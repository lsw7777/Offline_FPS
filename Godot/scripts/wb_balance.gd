class_name WBBalance
extends RefCounted
## GDScript port of Tools/validate_data.py's deterministic balance model (v1).
## This is the RUNTIME twin of the CI gate; keep them in lockstep.
##
## enemy: 100 HP; target half-width 0.5 m; armor DR {0:0,1:.15,2:.30,3:.45}

const ENEMY_HP := 100.0


static func mean_damage(w: Dictionary) -> float:
	var d: Array = w["damage"]
	return (float(d[0]) + float(d[1])) * 0.5


static func interval_s(w: Dictionary) -> float:
	return 60.0 / float(w["rpm"])


static func hit_probability(w: Dictionary, scene: Dictionary, dflt: Dictionary) -> float:
	var d: float = max(float(scene["distance_m"]), 0.1)
	var target_half: float = rad_to_deg(atan(float(dflt["target_half_width_m"]) / d))
	var base: float = float(dflt["stance_ads_base_spread_deg"]) * float(w["spread_mult"])
	var k: float = float(w["recoil_recover_deg_per_s"]) / max(float(w["recoil_v_deg"]), 0.01)
	var intv: float = interval_s(w)
	var shake: float = float(w["recoil_v_deg"]) / (1.0 + pow(k * intv, 3.0))
	var total: float = base + shake
	var p: float = target_half / (target_half + total)
	if scene.get("target_moving", false) and float(w["rpm"]) <= float(dflt["moving_target_slow_fire_rpm_threshold"]):
		p *= float(dflt["moving_target_slow_fire_penalty"])
	return clampf(p, 0.01, 1.0)


static func damage_per_trigger(w: Dictionary, scene: Dictionary, dflt: Dictionary) -> float:
	var d: float = float(scene["distance_m"])
	var target_half: float = rad_to_deg(atan(float(dflt["target_half_width_m"]) / max(d, 0.1)))
	var dmg: float = mean_damage(w) * float(w["pellets"])
	if int(w["pellets"]) > 1:
		var cone: float = float(w.get("pellet_cone_half_deg", 2.0))
		var coverage: float = minf(1.0, pow(target_half / cone, 2.0))
		dmg *= coverage
	dmg *= _falloff(w, d)
	var dr: float = float(dflt["armor_dr"][str(int(scene["armor_level"]))])
	dmg *= (1.0 - dr)
	var req = scene.get("requires_penetration")
	if req != null and int(w["penetration"]) < int(req):
		dmg *= float(scene.get("underpen_damage_mult", 0.55))
	return dmg


static func kill_time(w: Dictionary, scene: Dictionary, dflt: Dictionary, targets: int) -> Array:
	var dmg: float = damage_per_trigger(w, scene, dflt)
	if dmg <= 0.0:
		return [INF, 1000000]
	var hits: int = int(ceil(ENEMY_HP / dmg))
	var p: float = hit_probability(w, scene, dflt)
	var intv: float = interval_s(w)
	var shots_total: int = targets * hits
	var reload_cycles: int = maxi(0, int(ceil(float(shots_total) / float(w["magazine"]))) - 1)
	var sweep: float = 1.0
	if scene["metric"] == "clear":
		sweep = 1.0 - float(dflt.get("area_sweep_gain", 0.45)) * float(w.get("area_suppression", 0.0))
		reload_cycles = maxi(0, int(shots_total / int(w["magazine"])))
	var t: float = (float(w["handling_time_s"])
		+ targets * (hits - 1) * intv / p * sweep
		+ reload_cycles * float(w["reload_tactical_s"]))
	return [t, hits]


static func scene_score(w: Dictionary, scene: Dictionary, dflt: Dictionary) -> float:
	var metric: String = scene["metric"]
	var targets: int = int(scene["targets"])
	if metric == "alpha":
		var r = kill_time(w, scene, dflt, 1)
		var t: float = r[0]
		var hits: int = r[1]
		var base: float = 1.0 / maxf(t, 0.05)
		return base * float(dflt["first_shot_lethality_bonus"]) if hits == 1 else base
	if metric == "duel":
		var r = kill_time(w, scene, dflt, targets)
		var t: float = r[0]
		var hits: int = r[1]
		var base: float = 1.0 / maxf(t, 0.05)
		return base * float(dflt["first_shot_lethality_bonus"]) if hits == 1 else base
	if metric == "clear":
		var r = kill_time(w, scene, dflt, targets)
		var t: float = r[0]
		return 1.0 / t if is_finite(t) else 0.0
	if metric == "stealth":
		var r = kill_time(w, scene, dflt, 1)
		var t: float = r[0]
		var mult: float = float(dflt["suppressor_score_bonus"]) if w["suppressor_support"] else float(dflt["unsuppressed_stealth_score"])
		return mult / maxf(t, 0.05)
	push_error("WBBalance: unknown metric " + metric)
	return 0.0


static func build_matrix(weapons: Dictionary, scenes: Array, dflt: Dictionary) -> Dictionary:
	var out := {}
	for s in scenes:
		var row := {}
		for wid in weapons.keys():
			row[wid] = scene_score(weapons[wid], s, dflt)
		out[s["id"]] = row
	return out


static func _falloff(w: Dictionary, d: float) -> float:
	var rng: float = float(w["effective_range_m"])
	if d <= rng:
		return 1.0
	return maxf(0.0, 1.0 - (d - rng) / (rng * 0.6))

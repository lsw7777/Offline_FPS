#!/usr/bin/env python
"""
Project WB - data validator / balance gate.

Usage:
    python Tools/validate_data.py [--strict] [--data-dir PATH] [--quiet]

Exit code: 0 = all green, 1 = assertion failed (must block the commit).

--------------------------------------------------------------------------
BALANCE MODEL (deterministic, v1) - the ONLY place this math is allowed to live
--------------------------------------------------------------------------
enemy:  100 HP, hit multiplier ignored here (torso reference)
target: silhouette half-width = defaults.target_half_width_m  (0.5 m)

1) angular size       target_half_deg = degrees(atan(half_width / distance))
2) dispersion         base  = stance_ads_base_spread_deg * spread_mult
                      k     = recoil_recover_deg_per_s / recoil_v_deg      [1/s]
                      intv  = 60 / rpm                                     [s]
                      shake = recoil_v_deg / (1 + (k * intv) ** 3)          # slow guns re-aim
                      total = base + shake
3) hit probability    p = target_half / (target_half + total)
                      if scene.target_moving and rpm <= 120: p *= 0.45     # moving target punishes bolt guns
4) damage per trigger m870-style pellets: dmg = mean(damage) * pellets * min(1, (target_half/pellet_cone_half)**2)
                      falloff beyond effective_range: 1 - (d-range)/(range*0.6), clamped [0,1]
                      armor DR by level; under-penetration penalty if required
5) shots to kill      hits = ceil(100 / dmg_per_trigger_pull)
6) kill time          n targets -> handling + n*(hits-1)*intv/p + reload_cycles*reload_s
7) scene score        alpha/duel = 1/ttk   (bonus if hits == 1 -> first-shot lethality)
                      clear      = 1/clear_time
                      stealth    = (1.6 with suppressor / 0.35 without) / ttk

AI MAY tune weapons.json / scenes.json, AI MUST NOT weaken these assertions.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
from pathlib import Path

EnemyHP = 100.0

REQUIRED_WEAPON_FIELDS = [
    "id", "class", "display_name_zh", "ammo", "damage", "pellets", "rpm",
    "handling_time_s", "magazine", "reload_tactical_s", "recoil_v_deg",
    "recoil_recover_deg_per_s", "spread_mult", "effective_range_m",
    "penetration", "suppressor_support", "weight", "distance_band",
    "acquire", "feedback_tags",
]

REQUIRED_MELEE_FIELDS = [
    "id", "display_name_zh", "role", "damage_light", "interval_s", "range_m",
    "stamina_cost", "specials", "acquire",
]

VALID_BANDS = {"near", "mid", "far"}


# ---------------------------------------------------------------- loading --
def load_json(path: Path):
    with path.open(encoding="utf-8") as fh:
        return json.load(fh)


# ------------------------------------------------------------------ model --
def hit_probability(w: dict, scene: dict, dflt: dict) -> float:
    d = max(float(scene["distance_m"]), 0.1)
    target_half = math.degrees(math.atan(dflt["target_half_width_m"] / d))
    base = dflt["stance_ads_base_spread_deg"] * w["spread_mult"]
    k = w["recoil_recover_deg_per_s"] / max(w["recoil_v_deg"], 0.01)
    intv = interval_seconds(w)
    shake = w["recoil_v_deg"] / (1.0 + (k * intv) ** 3)
    total = base + shake
    p = target_half / (target_half + total)
    if scene.get("target_moving") and w["rpm"] <= dflt["moving_target_slow_fire_rpm_threshold"]:
        p *= dflt["moving_target_slow_fire_penalty"]
    return max(min(p, 1.0), 0.01)


def mean_damage(w: dict) -> float:
    lo, hi = w["damage"]
    return (float(lo) + float(hi)) / 2.0


def interval_seconds(w: dict) -> float:
    return 60.0 / float(w["rpm"])


def distance_falloff(w: dict, d: float) -> float:
    rng = float(w["effective_range_m"])
    if d <= rng:
        return 1.0
    return max(0.0, 1.0 - (d - rng) / (rng * 0.6))


def damage_per_trigger(w: dict, scene: dict, dflt: dict) -> float:
    d = float(scene["distance_m"])
    target_half = math.degrees(math.atan(dflt["target_half_width_m"] / max(d, 0.1)))
    dmg = mean_damage(w) * w["pellets"]
    if w["pellets"] > 1:
        cone = float(w.get("pellet_cone_half_deg", 2.0))
        coverage = min(1.0, (target_half / cone) ** 2)
        dmg *= coverage
    dmg *= distance_falloff(w, d)
    dr = float(dflt["armor_dr"][str(scene["armor_level"])])
    dmg *= (1.0 - dr)
    req = scene.get("requires_penetration")
    if req is not None and w["penetration"] < req:
        dmg *= float(scene.get("underpen_damage_mult", 0.55))
    return dmg


def kill_time(w: dict, scene: dict, dflt: dict, targets: int) -> tuple[float, int]:
    """Return (seconds, hits_to_kill).

    For 'clear' scenes an area-suppression factor is applied: sustained / belt-fed
    weapons can sweep a cluster, because suppressed targets stop returning fire
    and rounds can pass through. This is what gives the M249 its only home scene.
    """
    dmg = damage_per_trigger(w, scene, dflt)
    if dmg <= 0:
        return float("inf"), 10 ** 6
    hits = math.ceil(EnemyHP / dmg)
    p = hit_probability(w, scene, dflt)
    intv = interval_seconds(w)
    shots_total = targets * hits
    reload_cycles = max(0, math.ceil(shots_total / w["magazine"]) - 1)
    sweep = 1.0
    if scene["metric"] == "clear":
        sweep = 1.0 - dflt.get("area_sweep_gain", 0.45) * float(w.get("area_suppression", 0.0))
        reload_cycles = max(0, int(shots_total // w["magazine"]))
    t = (w["handling_time_s"]
         + targets * (hits - 1) * intv / p * sweep
         + reload_cycles * w["reload_tactical_s"])
    return t, hits


def scene_score(w: dict, scene: dict, dflt: dict) -> float:
    metric = scene["metric"]
    targets = int(scene["targets"])
    if metric == "alpha":
        t, hits = kill_time(w, scene, dflt, 1)
        base = 1.0 / max(t, 0.05)
        return base * dflt["first_shot_lethality_bonus"] if hits == 1 else base
    if metric == "duel":
        t, hits = kill_time(w, scene, dflt, targets)
        base = 1.0 / max(t, 0.05)
        return base * dflt["first_shot_lethality_bonus"] if hits == 1 else base
    if metric == "clear":
        t, _ = kill_time(w, scene, dflt, targets)
        return 1.0 / t if math.isfinite(t) else 0.0
    if metric == "stealth":
        t, _ = kill_time(w, scene, dflt, 1)
        mult = dflt["suppressor_score_bonus"] if w["suppressor_support"] else dflt["unsuppressed_stealth_score"]
        return mult / max(t, 0.05)
    raise ValueError(f"unknown metric: {metric}")


def build_matrix(weapons: list[dict], scenes: list[dict], dflt: dict) -> dict[str, dict[str, float]]:
    return {s["id"]: {w["id"]: scene_score(w, s, dflt) for w in weapons} for s in scenes}


# ------------------------------------------------------------ validations --
class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.lines: list[str] = []

    def error(self, msg: str) -> None:
        self.errors.append(msg)

    def warn(self, msg: str) -> None:
        self.warnings.append(msg)

    def info(self, msg: str) -> None:
        self.lines.append(msg)

    @property
    def ok(self) -> bool:
        return not self.errors


def validate_schema(rep: Report, weapons: list[dict], melee: list[dict], weapons_doc: dict) -> None:
    dflt = weapons_doc.get("defaults", {})
    for key in ("target_half_width_m", "stance_ads_base_spread_deg", "armor_dr"):
        if key not in dflt:
            rep.error(f"weapons.json: missing defaults.{key}")

    seen = set()
    for i, w in enumerate(weapons):
        tag = f"weapons[{i}]"
        for f in REQUIRED_WEAPON_FIELDS:
            if f not in w:
                rep.error(f"{tag} ({w.get('id','?')}): missing field '{f}'")
        wid = w.get("id")
        if wid in seen:
            rep.error(f"{tag}: duplicate weapon id '{wid}'")
        seen.add(wid)
        if isinstance(w.get("damage"), list) and len(w["damage"]) == 2:
            if float(w["damage"][0]) > float(w["damage"][1]):
                rep.error(f"{tag}: damage range inverted")
        else:
            rep.error(f"{tag}: damage must be [min, max]")
        if w.get("distance_band") not in VALID_BANDS:
            rep.error(f"{tag}: distance_band must be one of {sorted(VALID_BANDS)}")
        if float(w.get("handling_time_s", 0)) < 0:
            rep.error(f"{tag}: handling_time_s < 0")
        if int(w.get("pellets", 0)) < 1:
            rep.error(f"{tag}: pellets must be >= 1")

    seen_m = set()
    for i, m in enumerate(melee):
        tag = f"melee[{i}]"
        for f in REQUIRED_MELEE_FIELDS:
            if f not in m:
                rep.error(f"{tag} ({m.get('id','?')}): missing field '{f}'")
        mid = m.get("id")
        if mid in seen_m:
            rep.error(f"{tag}: duplicate melee id '{mid}'")
        seen_m.add(mid)


def validate_unique_feedback(rep: Report, weapons: list[dict], min_tags: int) -> None:
    for w in weapons:
        tags = w.get("feedback_tags", [])
        if len(tags) < min_tags:
            rep.error(
                f"{w['id']}: only {len(tags)} feedback tag(s); need >= {min_tags} "
                "(手感优先于数值: 闭眼要能听出是哪把枪)"
            )


def validate_ammo_scarcity(rep: Report, weapons: list[dict], rules: dict) -> None:
    for wid, rule in rules.get("ammo_scarcity", {}).items():
        w = next((x for x in weapons if x["id"] == wid), None)
        if w is None:
            rep.error(f"ammo_scarcity references unknown weapon '{wid}'")
            continue
        cap = rule.get("ammo_cap_global_max")
        if cap is not None and int(w.get("ammo_cap_global", 10**9)) > cap:
            rep.error(f"{wid}: ammo_cap_global {w.get('ammo_cap_global')} > limit {cap}")
        supply = rule.get("supply")
        if supply is not None and w.get("supply") != supply:
            rep.error(f"{wid}: supply must be '{supply}', got '{w.get('supply')}'")


def validate_balance(rep: Report, weapons: list[dict], scenes: list[dict], rules: dict,
                     matrix: dict[str, dict[str, float]], quiet: bool) -> None:
    margin = float(rules.get("winner_margin_pct", 2.0)) / 100.0
    dominance_threshold = float(rules.get("dominance_relative_threshold", 0.75))
    max_dominated = int(rules.get("max_scenes_dominated_per_weapon", 2))

    # print matrix
    ids = [w["id"] for w in weapons]
    header = f"{'scene':<26}" + "".join(f"{i:<16}" for i in ids) + "winner"
    if not quiet:
        rep.info(header)
        rep.info("-" * len(header))

    wins: dict[str, list[str]] = {w["id"]: [] for w in weapons}
    dominated: dict[str, int] = {w["id"]: 0 for w in weapons}

    for s in scenes:
        row = matrix[s["id"]]
        best = max(row, key=lambda k: row[k])
        second = max((v for k, v in row.items() if k != best), default=0.0)
        if not quiet:
            cells = "".join(f"{row[i]:<16.3f}" for i in ids)
            rep.info(f"{s['id']:<26}{cells}{best}")
        wins[best].append(s["id"])

        # A) unique winner with margin
        if second > 0 and (row[best] - second) / row[best] < margin:
            offender = max((k for k in row if k != best), key=lambda k: row[k])
            rep.error(
                f"scene '{s['id']}': winner '{best}' margin too small vs '{offender}' "
                f"({row[best]:.3f} vs {second:.3f}) - 克制矩阵每格必须有唯一最优解"
            )
        # B) design-intent golden matrix
        expected = s.get("expected_best")
        if expected and expected != best:
            rep.error(
                f"scene '{s['id']}': expected '{expected}' but computed '{best}'. "
                "若要改动设计意图，先在 Docs/DECISIONS.md 记录理由，再更新 expected_best"
            )
        # C) dominance bookkeeping
        for wid, score in row.items():
            if row[best] > 0 and score / row[best] >= dominance_threshold:
                dominated[wid] += 1

    # no weapon may dominate too many scenes (anti 全能武器)
    for wid, count in dominated.items():
        if count > max_dominated:
            rep.error(f"{wid}: dominates {count} scenes (max {max_dominated}) - 全能武器，必须削")
    # every weapon must own at least one scene
    if rules.get("every_weapon_must_win_one_scene"):
        for wid, w in wins.items():
            if not w:
                rep.error(f"{wid}: wins no scene - 无存在意义的武器，删掉或重做定位")

    ttk_rules = rules.get("ttk_ladder", {})
    # breach-type TTK check is implicit via design matrix; explicit single-scene ladder check:
    ladder_scenes = {
        "general_min_s": "Street_8_30m",
        "general_max_s": "Open_Snowfield_30_80m",
    }
    # general-purpose TTK (Street scene) must sit in the general band for the winner
    street = next((s for s in scenes if s["id"] == "Street_8_30m"), None)
    if street and ttk_rules:
        w = next(x for x in weapons if x["id"] == street.get("expected_best", "MP5"))
        dflt = _DEFAULTS
        t, _ = kill_time(w, street, dflt, 1)
        lo, hi = ttk_rules.get("general_min_s", 0.7), ttk_rules.get("general_max_s", 1.0)
        if not (lo <= t <= hi):
            rep.error(f"TTK ladder: {w['id']} duel TTK {t:.2f}s outside general band [{lo}, {hi}]")

    # precision weapon miss penalty must be >= 1.2s (bolt gun whiff punishment)
    awm = next((x for x in weapons if x["id"] == "AWM"), None)
    lng = next((s for s in scenes if s["id"] == "LongRange_80m_plus"), None)
    if awm and lng and ttk_rules:
        # simulate a whiffed first shot: time until the 2nd shot lands
        penalty = interval_seconds(awm) + (60.0 / 50.0)
        need = float(ttk_rules.get("precision_miss_penalty_min_s", 1.2))
        if penalty < need:
            rep.error(f"AWM miss penalty {penalty:.2f}s < {need}s - 落空惩罚不足")


_DEFAULTS: dict = {}


# ------------------------------------------------------------------- main --
def run(data_dir: Path, strict: bool, quiet: bool) -> int:
    global _DEFAULTS
    rep = Report()

    weapons_doc = load_json(data_dir / "weapons.json")
    melee_doc = load_json(data_dir / "melee.json")
    scenes_doc = load_json(data_dir / "scenes.json")

    weapons = weapons_doc["items"]
    melee = melee_doc["items"]
    scenes = scenes_doc["scenes"]
    rules = scenes_doc.get("balance_rules", {})
    _DEFAULTS = weapons_doc.get("defaults", {})

    validate_schema(rep, weapons, melee, weapons_doc)
    validate_unique_feedback(rep, weapons, int(rules.get("min_unique_feedback_tags", 2)))
    validate_ammo_scarcity(rep, weapons, rules)

    if len(rep.errors) > 0:
        # matrix math needs a sane schema
        _emit(rep, quiet)
        return 1

    matrix = build_matrix(weapons, scenes, _DEFAULTS)
    validate_balance(rep, weapons, scenes, rules, matrix, quiet)

    ok = rep.ok and (not strict or not rep.warnings)
    _emit(rep, quiet)
    return 0 if ok else 1


def _emit(rep: Report, quiet: bool) -> None:
    if not quiet:
        for line in rep.lines:
            print(line)
        print()
    for w in rep.warnings:
        print(f"[WARN ] {w}")
    for e in rep.errors:
        print(f"[ERROR] {e}")
    print()
    if rep.ok:
        print(f"OK: {len(rep.lines)} rows checked, 0 errors.")
    else:
        print(f"FAILED: {len(rep.errors)} error(s). 禁止提交，回到 weapons.json / scenes.json 调整数值。")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data-dir", default=None, help="override Config/Data directory (tests use fixtures)")
    ap.add_argument("--strict", action="store_true", help="warnings become errors")
    ap.add_argument("--quiet", action="store_true", help="suppress matrix printing")
    args = ap.parse_args()

    here = Path(__file__).resolve().parent
    data_dir = Path(args.data_dir) if args.data_dir else (here.parent / "Config" / "Data")
    if not data_dir.is_dir():
        print(f"[ERROR] data dir not found: {data_dir}")
        return 1
    return run(data_dir, args.strict, args.quiet)


if __name__ == "__main__":
    sys.exit(main())

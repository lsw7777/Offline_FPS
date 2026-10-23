extends Node
## Weapon system: loads weapons.json, handles fire (hitscan + tracer + muzzle
## flash), recoil, reload, weapon switching. All numbers come from the data file.

signal weapon_changed(id: String, display: String)
signal ammo_changed(id: String, ammo: int, mag: int)
signal recoil(kick_v: float, kick_h: float, recover: float)
signal hit(lethal: bool)
signal shot_fired

const FOV_HIP := 75.0
const FOV_ADS := 55.0

var weapons := {}
var weapon_order: Array = []
var current := ""
var ammo_in_mag := 0
var cooldown := 0.0
var reloading := false
var reload_t := 0.0
var aiming := false
var ui_blocked := false
var melee_mode := false

@onready var camera: Camera3D = get_node("../Camera3D")
@onready var player: CharacterBody3D = get_parent()
var weapon_model = null


func _ready() -> void:
	weapons = WBData.weapons()
	weapon_order = WBData.weapons_order()
	weapon_model = get_node_or_null("../Camera3D/WeaponModel")
	if weapon_order.size() > 0:
		equip(weapon_order[0])


func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)

	# aim-down-sights zoom (never zoom while melee)
	var want_fov := FOV_HIP
	if not melee_mode and aiming:
		want_fov = FOV_ADS
	if camera:
		camera.fov = lerpf(camera.fov, want_fov, delta * 10.0)

	if reloading:
		reload_t -= delta
		if reload_t <= 0.0:
			reloading = false
			ammo_in_mag = int(weapons[current]["magazine"])
			ammo_changed.emit(current, ammo_in_mag, int(weapons[current]["magazine"]))

	if not melee_mode:
		for i in range(weapon_order.size()):
			if Input.is_action_just_pressed("weapon_%d" % (i + 1)):
				equip(weapon_order[i])

		if Input.is_action_just_pressed("reload"):
			begin_reload()

		if Input.is_action_pressed("fire"):
			fire()


func equip(id: String) -> void:
	if not weapons.has(id):
		return
	current = id
	ammo_in_mag = int(weapons[id]["magazine"])
	reloading = false
	cooldown = 0.0
	if weapon_model and weapon_model.has_method("build"):
		weapon_model.build(weapons[id])
	weapon_changed.emit(id, weapons[id]["display_name_zh"])
	ammo_changed.emit(id, ammo_in_mag, int(weapons[id]["magazine"]))


func begin_reload() -> void:
	if reloading or current == "":
		return
	if ammo_in_mag >= int(weapons[current]["magazine"]):
		return
	reloading = true
	reload_t = float(weapons[current]["reload_tactical_s"])


## Refill the current weapon to a full magazine (used when switching maps).
func reset_ammo() -> void:
	if current == "":
		return
	ammo_in_mag = int(weapons[current]["magazine"])
	reloading = false
	cooldown = 0.0
	ammo_changed.emit(current, ammo_in_mag, int(weapons[current]["magazine"]))


## Called by the player when the ADS toggle flips.
func on_aim_changed(a: bool) -> void:
	aiming = a
	if weapon_model and weapon_model.has_method("set_aiming"):
		weapon_model.set_aiming(a)


## Called by the player when switching between ranged and melee.
func on_mode_changed(is_melee: bool) -> void:
	melee_mode = is_melee
	if is_melee:
		aiming = false
	if weapon_model and weapon_model.has_method("set_active"):
		weapon_model.set_active(not is_melee)


func fire() -> void:
	# guns do not fire in melee mode
	if melee_mode:
		return
	# never shoot while the settings panel is open
	if ui_blocked:
		return
	# when the cursor is free, do not shoot if the click lands on a HUD control
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and get_viewport().gui_get_hovered_control() != null:
		return
	if reloading or current == "" or cooldown > 0.0 or ammo_in_mag <= 0:
		return

	var w: Dictionary = weapons[current]
	var interval := 60.0 / float(w["rpm"])
	cooldown = interval
	ammo_in_mag -= 1

	# spread: hip-fire is loose, aim-down-sights is tight (same weapon, better accuracy)
	var base_spread := 0.08 if aiming else 0.7
	var spread := base_spread * float(w["spread_mult"])
	var fwd := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y
	var ang_h := deg_to_rad(randf_range(-spread, spread))
	var ang_v := deg_to_rad(randf_range(-spread, spread))
	var dir := fwd.rotated(right, ang_v).rotated(up, ang_h).normalized()

	var from := camera.global_position
	var to := from + dir * float(w["effective_range_m"])
	var space := player.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [player.get_rid()]
	var res := space.intersect_ray(q)

	var hit_point := to
	if not res.is_empty():
		hit_point = res["position"]
		var collider: Object = res["collider"]
		if collider and collider.has_method("take_damage"):
			collider.take_damage(_damage(w))
			hit.emit(false)

	# muzzle flash + tracer + ejected casing
	if weapon_model and weapon_model.has_method("flash"):
		weapon_model.flash()
	if weapon_model and weapon_model.has_method("eject_shell"):
		weapon_model.eject_shell()
	_spawn_tracer(hit_point)
	shot_fired.emit()

	# recoil kick: 60% fixed + 40% random (docs section 6.1)
	var kick_v := float(w["recoil_v_deg"]) * (0.6 + 0.4 * randf())
	var kick_h := float(w["recoil_h_deg"]) * (0.6 + 0.4 * randf_range(-1.0, 1.0))
	recoil.emit(kick_v, kick_h, float(w["recoil_recover_deg_per_s"]))

	ammo_changed.emit(current, ammo_in_mag, int(w["magazine"]))


func _spawn_tracer(hit_point: Vector3) -> void:
	var muzzle: Vector3 = weapon_model.get_muzzle_global() if weapon_model else camera.global_position
	var dir: Vector3 = hit_point - muzzle
	var length: float = dir.length()
	if length < 0.01:
		return
	dir = dir.normalized()

	var tracer := WBPrim.mesh_box(Vector3(0.03, 0.03, length), Color(1, 0.9, 0.5), Color(1, 0.8, 0.4), 3.0)
	var parent := player.get_parent()
	if parent == null:
		tracer.free()
		return
	parent.add_child(tracer)
	tracer.position = muzzle + dir * length * 0.5
	var upv := Vector3.UP
	if absf(dir.dot(upv)) > 0.99:
		upv = Vector3.RIGHT
	tracer.look_at(muzzle + dir, upv)
	get_tree().create_timer(0.06).timeout.connect(tracer.queue_free)


func _damage(w: Dictionary) -> float:
	var d: Array = w["damage"]
	return (float(d[0]) + float(d[1])) * 0.5 * float(w["pellets"])

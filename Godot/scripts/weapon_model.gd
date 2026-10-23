extends Node3D
## Detailed first-person weapon viewmodel + arms, built procedurally.
## Each weapon class gets a distinct, multi-part silhouette.

const METAL := Color(0.17, 0.17, 0.19)
const METAL_HI := Color(0.28, 0.28, 0.31)
const METAL_DARK := Color(0.08, 0.08, 0.10)
const WOOD := Color(0.42, 0.28, 0.16)
const POLY := Color(0.12, 0.12, 0.13)
const SKIN := Color(0.86, 0.70, 0.56)
const SLEEVE := Color(0.16, 0.20, 0.22)

var muzzle: Marker3D = null
var _gun_root: Node3D = null
var _base_pos := Vector3(0.32, -0.28, -0.55)
var _ads_pos := Vector3(0.0, -0.075, -0.40)
var _t := 0.0
var aiming := false
var _aim_t := 0.0
var _class := ""
var _anim := ""
var _anim_t := 0.0
var _anim_dur := 1.0


func _ready() -> void:
	set_process(true)
	muzzle = Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0.03, -0.70)
	add_child(muzzle)


func set_aiming(a: bool) -> void:
	aiming = a


## Show/hide the gun (hidden while in melee mode).
func set_active(a: bool) -> void:
	aiming = false
	_aim_t = 0.0
	if _gun_root:
		_gun_root.visible = a


func _process(delta: float) -> void:
	if _gun_root == null:
		return

	# blend between hip-fire pose and aim-down-sights pose
	_aim_t = move_toward(_aim_t, 1.0 if aiming else 0.0, delta * 9.0)

	_t += delta
	var spd := 0.0
	var cam := get_parent()
	if cam and cam.get_parent() is CharacterBody3D:
		var v: Vector3 = cam.get_parent().velocity
		spd = Vector2(v.x, v.z).length()

	# sway only while hip-firing (steady when aiming)
	var amp := minf(spd / 6.0, 1.0) * 0.012 * (1.0 - _aim_t)
	var target := _base_pos.lerp(_ads_pos, _aim_t)
	target.y += sin(_t * 10.0) * amp
	target.x += sin(_t * 5.0) * amp * 0.5

	# ---- reload / switch pose overlay ----
	var off := Vector3.ZERO
	var rot := Vector3.ZERO
	if _anim != "":
		_anim_t -= delta
		var p: float = 1.0 - clampf(_anim_t / maxf(_anim_dur, 0.01), 0.0, 1.0)
		var k: float = sin(p * PI)
		if _anim == "reload":
			match _class:
				"PumpShotgun":
					# pump the slide back and forth
					off.y -= 0.13 * k
					off.z += 0.02 * sin(p * PI * 6.0)
					rot.x += 14.0 * k
				"BoltSniper":
					off.y -= 0.15 * k
					rot.x += 22.0 * k
					rot.z += 32.0 * k
				"SquadAutomaticWeapon":
					off.y -= 0.24 * k
					off.z += 0.06 * k
					rot.x += 26.0 * k
					rot.z += 20.0 * k
				"HeavyPistol":
					off.y -= 0.12 * k
					rot.z += 42.0 * k
					rot.x += 16.0 * k
				_:
					off.y -= 0.16 * k
					off.z += 0.05 * k
					rot.x += 25.0 * k
					rot.z += 22.0 * k
		elif _anim == "switch":
			off.y -= 0.34 * k
			off.z += 0.10 * k
			rot.x += 38.0 * k
		elif _anim == "inspect":
			off.y += 0.03 * k
			rot.y += 58.0 * k
			rot.z += 18.0 * k
		if _anim_t <= 0.0:
			_anim = ""

	_gun_root.position = target + off
	_gun_root.rotation_degrees = rot


func _switch_duration(cls: String) -> float:
	match cls:
		"HeavyPistol":
			return 0.34
		"SMG":
			return 0.44
		"PumpShotgun":
			return 0.58
		"BoltSniper":
			return 0.70
		"SquadAutomaticWeapon":
			return 0.80
		_:
			return 0.50


## Play the reload animation; duration normally equals reload_tactical_s.
func play_reload(dur: float) -> void:
	_anim = "reload"
	_anim_dur = maxf(dur, 0.2)
	_anim_t = _anim_dur
	_drop_mag()


## Play the weapon-raise animation when a gun is equipped / drawn.
func play_switch() -> void:
	_anim = "switch"
	_anim_dur = _switch_duration(_class)
	_anim_t = _anim_dur


## Inspect the weapon (middle mouse): turn it to show its side, then back.
func play_inspect() -> void:
	if _anim == "reload":
		return
	_anim = "inspect"
	_anim_dur = 1.4
	_anim_t = _anim_dur


func _drop_mag() -> void:
	if _gun_root == null or _class == "PumpShotgun":
		return
	var cam := get_parent()
	if cam == null:
		return
	var root: Node = cam.get_parent()
	if root == null:
		return
	var world: Node = root.get_parent()
	if world == null:
		return
	var mag := MeshInstance3D.new()
	mag.set_script(load("res://Godot/scripts/shell.gd"))
	var bm := BoxMesh.new()
	bm.size = Vector3(0.05, 0.15, 0.07)
	mag.mesh = bm
	mag.material_override = WBPrim.mat(Color(0.14, 0.14, 0.16), Color(0, 0, 0), 1.0, 0.7, 0.4)
	world.add_child(mag)
	mag.global_position = _gun_root.to_global(Vector3(0.0, -0.16, 0.10))
	var cam3d := cam as Camera3D
	if cam3d:
		var basis: Basis = cam3d.global_transform.basis
		mag.set("vel", basis.y * -1.2 + basis.x * 0.4)
	mag.set("spin", Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-6, 6)))


## Eject a brass casing from the right side of the receiver.
func eject_shell() -> void:
	if _gun_root == null:
		return
	var cam := get_parent()
	if cam == null:
		return
	var root: Node = cam.get_parent()
	if root == null:
		return
	var world: Node = root.get_parent()
	if world == null:
		return

	var shell := MeshInstance3D.new()
	shell.set_script(load("res://Godot/scripts/shell.gd"))
	var bm := BoxMesh.new()
	bm.size = Vector3(0.022, 0.022, 0.055)
	shell.mesh = bm
	shell.material_override = WBPrim.mat(Color(0.86, 0.66, 0.22), Color(0, 0, 0), 1.0, 0.9, 0.35)
	world.add_child(shell)
	shell.global_position = _gun_root.to_global(Vector3(0.055, 0.02, -0.02))

	var cam3d := cam as Camera3D
	if cam3d:
		var basis: Basis = cam3d.global_transform.basis
		shell.set("vel", basis.x * 3.2 + basis.y * 2.2 + basis.z * 1.2)
	shell.set("spin", Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9)))


func build(weapon: Dictionary) -> void:
	_clear_gun()
	_class = weapon.get("class", "")
	var cls: String = _class
	_gun_root = Node3D.new()
	_gun_root.name = "Gun"
	_gun_root.position = _base_pos
	add_child(_gun_root)

	var end_z := -0.70
	match cls:
		"HeavyPistol":
			end_z = _build_pistol()
		"SMG":
			end_z = _build_smg()
		"PumpShotgun":
			end_z = _build_shotgun()
		"BoltSniper":
			end_z = _build_sniper()
		"SquadAutomaticWeapon":
			end_z = _build_mg()
		_:
			end_z = _build_rifle()

	_build_arms(cls)
	if muzzle:
		muzzle.position = Vector3(0, 0.02, end_z)


# --------------------------------------------------------------- builders --
func _add(mesh: MeshInstance3D, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	mesh.position = pos
	mesh.rotation_degrees += rot
	_gun_root.add_child(mesh)
	return mesh


func _cyl_z(height: float, radius: float, color: Color) -> MeshInstance3D:
	var m := WBPrim.mesh_cyl(height, radius, color)
	m.rotation_degrees = Vector3(90, 0, 0)
	return m


func _common_sights(front_z: float) -> void:
	_add(WBPrim.mesh_box(Vector3(0.02, 0.06, 0.02), METAL_DARK), Vector3(0, 0.09, front_z))
	_add(WBPrim.mesh_box(Vector3(0.05, 0.03, 0.03), METAL_DARK), Vector3(0, 0.085, 0.06))
	_add(WBPrim.mesh_box(Vector3(0.03, 0.015, 0.10), METAL_HI), Vector3(0, 0.075, -0.12))


func _build_pistol() -> float:
	_add(WBPrim.mesh_box(Vector3(0.06, 0.09, 0.26), METAL), Vector3(0, 0, -0.02))
	_add(WBPrim.mesh_box(Vector3(0.065, 0.045, 0.26), METAL_HI), Vector3(0, 0.055, -0.02))  # slide
	_add(_cyl_z(0.14, 0.024, METAL_DARK), Vector3(0, 0.01, -0.22))
	_add(WBPrim.mesh_box(Vector3(0.05, 0.14, 0.07), POLY), Vector3(0, -0.11, 0.06), Vector3(12, 0, 0))
	_add(WBPrim.mesh_box(Vector3(0.03, 0.02, 0.05), METAL_HI), Vector3(0, -0.05, 0.02))
	_common_sights(-0.08)
	return -0.30


func _build_smg() -> float:
	_add(WBPrim.mesh_box(Vector3(0.07, 0.10, 0.34), METAL), Vector3(0, 0, -0.04))
	_add(WBPrim.mesh_box(Vector3(0.06, 0.07, 0.18), POLY), Vector3(0, 0.005, -0.28))
	_add(_cyl_z(0.16, 0.019, METAL_DARK), Vector3(0, 0.02, -0.42))
	_add(_cyl_z(0.05, 0.026, METAL_HI), Vector3(0, 0.02, -0.50))
	_add(WBPrim.mesh_box(Vector3(0.05, 0.16, 0.06), METAL), Vector3(0, -0.16, 0.06))
	_add(WBPrim.mesh_box(Vector3(0.05, 0.12, 0.07), POLY), Vector3(0, -0.12, 0.09), Vector3(10, 0, 0))
	_add(WBPrim.mesh_box(Vector3(0.05, 0.08, 0.14), METAL), Vector3(0, -0.01, 0.20))
	_common_sights(-0.32)
	return -0.52


func _build_rifle() -> float:
	_add(WBPrim.mesh_box(Vector3(0.07, 0.10, 0.42), METAL), Vector3(0, 0, -0.06))
	_add(WBPrim.mesh_box(Vector3(0.06, 0.075, 0.24), WOOD), Vector3(0, 0.005, -0.32))
	_add(_cyl_z(0.24, 0.019, METAL_DARK), Vector3(0, 0.02, -0.52))
	_add(_cyl_z(0.06, 0.028, METAL_HI), Vector3(0, 0.02, -0.66))
	var mag := _add(WBPrim.mesh_box(Vector3(0.055, 0.18, 0.08), METAL), Vector3(0, -0.18, 0.10), Vector3(0, 0, 16))
	_add(WBPrim.mesh_box(Vector3(0.05, 0.13, 0.07), WOOD), Vector3(0, -0.12, 0.06), Vector3(12, 0, 0))
	_add(WBPrim.mesh_box(Vector3(0.06, 0.09, 0.18), WOOD), Vector3(0, -0.01, 0.26))
	_add(WBPrim.mesh_box(Vector3(0.04, 0.02, 0.12), METAL_HI), Vector3(0.05, 0.03, 0.02))  # charging handle
	_common_sights(-0.42)
	return -0.72


func _build_shotgun() -> float:
	_add(WBPrim.mesh_box(Vector3(0.075, 0.10, 0.40), METAL_DARK), Vector3(0, 0, -0.06))
	_add(_cyl_z(0.34, 0.033, METAL_DARK), Vector3(0, 0.03, -0.42))
	_add(_cyl_z(0.26, 0.022, METAL), Vector3(0, -0.03, -0.36))  # tube magazine
	var pump := _add(WBPrim.mesh_box(Vector3(0.07, 0.08, 0.16), WOOD), Vector3(0, -0.02, -0.30))
	_add(WBPrim.mesh_box(Vector3(0.06, 0.10, 0.20), WOOD), Vector3(0, -0.01, 0.24))
	_add(WBPrim.mesh_box(Vector3(0.05, 0.13, 0.07), WOOD), Vector3(0, -0.12, 0.06), Vector3(12, 0, 0))
	_common_sights(-0.52)
	return -0.60


func _build_sniper() -> float:
	_add(WBPrim.mesh_box(Vector3(0.07, 0.10, 0.46), METAL), Vector3(0, 0, -0.06))
	_add(_cyl_z(0.44, 0.017, METAL_DARK), Vector3(0, 0.02, -0.62))
	_add(_cyl_z(0.07, 0.026, METAL_HI), Vector3(0, 0.02, -0.86))
	# scope: tube + two rings + lens
	_add(_cyl_z(0.30, 0.036, METAL_DARK), Vector3(0, 0.10, -0.14))
	_add(WBPrim.mesh_cyl(0.03, 0.042, METAL_HI), Vector3(0, 0.10, -0.02), Vector3(90, 0, 0))
	_add(WBPrim.mesh_cyl(0.03, 0.042, METAL_HI), Vector3(0, 0.10, -0.26), Vector3(90, 0, 0))
	_add(_cyl_z(0.02, 0.032, Color(0.3, 0.5, 0.7)), Vector3(0, 0.10, -0.30))
	# bolt handle
	_add(WBPrim.mesh_cyl(0.10, 0.012, METAL_HI), Vector3(0.06, 0.03, 0.02), Vector3(0, 0, 70))
	_add(WBPrim.mesh_box(Vector3(0.055, 0.18, 0.08), METAL), Vector3(0, -0.17, 0.12))
	_add(WBPrim.mesh_box(Vector3(0.05, 0.13, 0.07), WOOD), Vector3(0, -0.12, 0.06), Vector3(12, 0, 0))
	_add(WBPrim.mesh_box(Vector3(0.06, 0.10, 0.24), WOOD), Vector3(0, -0.02, 0.30))
	return -0.92


func _build_mg() -> float:
	_add(WBPrim.mesh_box(Vector3(0.09, 0.12, 0.44), METAL), Vector3(0, 0, -0.06))
	_add(_cyl_z(0.40, 0.024, METAL_DARK), Vector3(0, 0.02, -0.58))
	_add(_cyl_z(0.10, 0.032, METAL_HI), Vector3(0, 0.02, -0.80))
	_add(WBPrim.mesh_box(Vector3(0.07, 0.11, 0.16), POLY), Vector3(0, -0.01, -0.30))  # foregrip
	_add(WBPrim.mesh_box(Vector3(0.09, 0.16, 0.12), METAL_DARK), Vector3(0.02, -0.20, 0.04))  # box mag
	_add(WBPrim.mesh_box(Vector3(0.06, 0.10, 0.20), METAL), Vector3(0, -0.02, 0.28))
	# bipod
	_add(WBPrim.mesh_cyl(0.20, 0.010, METAL_HI), Vector3(-0.06, -0.14, -0.50), Vector3(0, 0, 20))
	_add(WBPrim.mesh_cyl(0.20, 0.010, METAL_HI), Vector3(0.06, -0.14, -0.50), Vector3(0, 0, -20))
	_common_sights(-0.48)
	return -0.86


func _build_arms(cls: String) -> void:
	var right_hand_z := 0.06
	var left_hand_z := -0.30
	if cls == "HeavyPistol":
		left_hand_z = 0.02

	# right arm (grip)
	_add(WBPrim.mesh_cyl(0.34, 0.045, SKIN), Vector3(0.12, -0.26, right_hand_z + 0.16), Vector3(64, 0, 8))
	_add(WBPrim.mesh_cyl(0.14, 0.055, SLEEVE), Vector3(0.16, -0.36, right_hand_z + 0.26), Vector3(64, 0, 8))
	_add(WBPrim.mesh_box(Vector3(0.07, 0.09, 0.10), SKIN), Vector3(0.02, -0.10, right_hand_z))
	# left arm (foregrip)
	_add(WBPrim.mesh_cyl(0.36, 0.043, SKIN), Vector3(-0.10, -0.26, left_hand_z + 0.10), Vector3(70, 0, -10))
	_add(WBPrim.mesh_cyl(0.14, 0.053, SLEEVE), Vector3(-0.15, -0.38, left_hand_z + 0.20), Vector3(70, 0, -10))
	_add(WBPrim.mesh_box(Vector3(0.07, 0.08, 0.10), SKIN), Vector3(0, -0.03, left_hand_z))


func _clear_gun() -> void:
	for c in get_children():
		if c.name == "Gun":
			c.free()
	_gun_root = null


func get_muzzle_global() -> Vector3:
	if muzzle == null:
		return global_position + Vector3(0, 0, -0.6)
	return muzzle.global_position


func flash() -> void:
	if muzzle == null:
		return
	var f := WBPrim.mesh_sphere(0.075, Color(1, 0.92, 0.45), Color(1, 0.8, 0.3), 3.0)
	f.scale = Vector3(1, 1, 0.5)
	muzzle.add_child(f)
	var light := OmniLight3D.new()
	light.light_color = Color(1, 0.8, 0.4)
	light.light_energy = 2.2
	light.omni_range = 3.5
	muzzle.add_child(light)
	get_tree().create_timer(0.05).timeout.connect(func():
		if is_instance_valid(f):
			f.queue_free()
		if is_instance_valid(light):
			light.queue_free())

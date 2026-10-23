extends Node3D
## First-person weapon viewmodel + arms, built procedurally and attached to the
## camera. Rebuilds per weapon so each gun has a distinct silhouette.

const METAL := Color(0.16, 0.16, 0.18)
const METAL_DARK := Color(0.09, 0.09, 0.11)
const WOOD := Color(0.45, 0.30, 0.18)
const SKIN := Color(0.88, 0.72, 0.58)
const ACCENT := Color(0.85, 0.55, 0.15)

var muzzle: Marker3D = null

var _flash: Node3D = null
var _flash_light: OmniLight3D = null


func _ready() -> void:
	# muzzle marker (gun tip)
	var m := Marker3D.new()
	m.name = "Muzzle"
	m.position = Vector3(0, 0.03, -0.62)
	add_child(m)
	muzzle = m


func build(weapon: Dictionary) -> void:
	_clear_gun()
	var cls: String = weapon.get("class", "")
	var root := Node3D.new()
	root.name = "Gun"
	root.position = Vector3(0.30, -0.26, -0.55)

	# common: receiver body
	root.add_child(_part(WBPrim.mesh_box(Vector3(0.07, 0.10, 0.42), METAL), Vector3(0, 0, -0.08)))
	# barrel (points -Z: cylinder default axis is Y, so rotate X by 90 deg)
	var barrel_len := 0.30
	var barrel_r := 0.022
	match cls:
		"HeavyPistol":
			barrel_len = 0.18; barrel_r = 0.03
		"PumpShotgun":
			barrel_len = 0.34; barrel_r = 0.032
		"BoltSniper":
			barrel_len = 0.46; barrel_r = 0.02
		"SquadAutomaticWeapon":
			barrel_len = 0.40; barrel_r = 0.026
	var barrel := WBPrim.mesh_cyl(barrel_len, barrel_r, METAL_DARK)
	barrel.rotation_degrees = Vector3(90, 0, 0)
	root.add_child(_part(barrel, Vector3(0, 0.02, -0.30 - barrel_len * 0.5 + 0.05)))

	# grip
	root.add_child(_part(WBPrim.mesh_box(Vector3(0.05, 0.14, 0.07), METAL_DARK), Vector3(0, -0.12, 0.06)))
	# magazine (rifle/smg) or stock
	match cls:
		"AssaultRifle":
			var mag := WBPrim.mesh_box(Vector3(0.05, 0.16, 0.08), METAL)
			mag.rotation_degrees = Vector3(0, 0, 18)
			root.add_child(_part(mag, Vector3(0, -0.16, 0.12)))
			root.add_child(_part(WBPrim.mesh_box(Vector3(0.06, 0.09, 0.16), WOOD), Vector3(0, -0.01, 0.24)))
			root.add_child(_part(WBPrim.mesh_box(Vector3(0.05, 0.06, 0.12), WOOD), Vector3(0, 0.06, -0.10)))
		"SMG":
			root.add_child(_part(WBPrim.mesh_box(Vector3(0.05, 0.18, 0.06), METAL), Vector3(0, -0.18, 0.10)))
			root.add_child(_part(WBPrim.mesh_box(Vector3(0.05, 0.07, 0.12), METAL), Vector3(0, -0.02, 0.18)))
		"PumpShotgun":
			root.add_child(_part(WBPrim.mesh_box(Vector3(0.06, 0.09, 0.16), WOOD), Vector3(0, -0.01, 0.22)))
			var tube := WBPrim.mesh_cyl(0.22, 0.02, METAL_DARK)
			tube.rotation_degrees = Vector3(90, 0, 0)
			root.add_child(_part(tube, Vector3(0, -0.05, -0.12)))
		"BoltSniper":
			root.add_child(_part(WBPrim.mesh_box(Vector3(0.06, 0.10, 0.18), WOOD), Vector3(0, -0.01, 0.26)))
			var scope := WBPrim.mesh_cyl(0.16, 0.035, METAL_DARK)
			scope.rotation_degrees = Vector3(90, 0, 0)
			root.add_child(_part(scope, Vector3(0, 0.09, -0.12)))
		"SquadAutomaticWeapon":
			root.add_child(_part(WBPrim.mesh_box(Vector3(0.09, 0.12, 0.30), METAL), Vector3(0, -0.05, -0.10)))
			root.add_child(_part(WBPrim.mesh_box(Vector3(0.08, 0.14, 0.10), METAL_DARK), Vector3(0, -0.18, 0.02)))
			root.add_child(_part(WBPrim.mesh_box(Vector3(0.06, 0.09, 0.14), METAL), Vector3(0, -0.01, 0.20)))
		_:
			pass

	# hands + forearms (skin)
	var lh := WBPrim.mesh_cyl(0.16, 0.035, SKIN)
	lh.rotation_degrees = Vector3(80, 0, 0)
	root.add_child(_part(lh, Vector3(-0.04, -0.10, 0.02)))
	var rh := WBPrim.mesh_cyl(0.14, 0.035, SKIN)
	rh.rotation_degrees = Vector3(75, 0, 0)
	root.add_child(_part(rh, Vector3(0.04, -0.14, 0.05)))

	add_child(root)


func _part(mi: MeshInstance3D, pos: Vector3) -> MeshInstance3D:
	mi.position = pos
	return mi


func _clear_gun() -> void:
	for c in get_children():
		if c.name == "Gun":
			c.free()


func get_muzzle_global() -> Vector3:
	if muzzle == null:
		return global_position + Vector3(0, 0, -0.6)
	return muzzle.global_position


## Brief muzzle flash at the gun tip.
func flash() -> void:
	if muzzle == null:
		return
	if _flash == null:
		_flash = WBPrim.mesh_sphere(0.07, Color(1, 0.9, 0.4), Color(1, 0.8, 0.3), 3.0)
		_flash.name = "MuzzleFlash"
		_flash.scale = Vector3(1, 1, 0.4)
		muzzle.add_child(_flash)
		_flash_light = OmniLight3D.new()
		_flash_light.light_color = Color(1, 0.8, 0.4)
		_flash_light.light_energy = 2.0
		_flash_light.omni_range = 3.0
		muzzle.add_child(_flash_light)
	_flash.visible = true
	_flash_light.visible = true
	get_tree().create_timer(0.05).timeout.connect(_hide_flash)


func _hide_flash() -> void:
	if _flash:
		_flash.visible = false
	if _flash_light:
		_flash_light.visible = false

extends Node3D
## First-person melee viewmodel (3 knives), built procedurally.
## Hidden while in ranged mode; shows a swing animation on attack.

const STEEL := Color(0.72, 0.74, 0.78)
const STEEL_DARK := Color(0.45, 0.47, 0.50)
const SKIN := Color(0.86, 0.70, 0.56)

var _root: Node3D = null
var _t := 0.0
var _attack_t := 0.0
var _switch_t := 0.0
var _switch_dur := 0.30
var _inspect_t := 0.0
var _active := false


func _ready() -> void:
	set_process(true)
	visible = false


func set_active(a: bool) -> void:
	_active = a
	visible = a
	if not a:
		_attack_t = 0.0


func build(data: Dictionary) -> void:
	if _root:
		_root.free()
		_root = null
	var id: String = data.get("id", "M9_Bayonet")

	_root = Node3D.new()
	_root.name = "Knife"
	_root.position = Vector3(0.30, -0.30, -0.50)
	_root.rotation_degrees = Vector3(8, -12, 0)
	add_child(_root)

	var blade_len := 0.30
	var blade_w := 0.012
	var handle_col := Color(0.18, 0.24, 0.16)
	match id:
		"KA-BAR":
			blade_len = 0.26
			blade_w = 0.017
			handle_col = Color(0.32, 0.22, 0.14)
		"Balisong":
			blade_len = 0.22
			blade_w = 0.010
			handle_col = Color(0.55, 0.56, 0.60)

	# handle
	if id == "Balisong":
		_add(WBPrim.mesh_box(Vector3(0.014, 0.05, 0.14), handle_col), Vector3(-0.018, 0, 0.03))
		_add(WBPrim.mesh_box(Vector3(0.014, 0.05, 0.14), handle_col), Vector3(0.018, 0, 0.03))
	else:
		_add(WBPrim.mesh_box(Vector3(0.036, 0.052, 0.14), handle_col), Vector3(0, 0, 0.03))

	# guard / bolster
	_add(WBPrim.mesh_box(Vector3(0.072, 0.062, 0.016), STEEL_DARK), Vector3(0, 0.004, -0.05))

	# blade (points -Z, slight upward cant)
	_add(WBPrim.mesh_box(Vector3(blade_w, 0.046, blade_len), STEEL), Vector3(0, 0.026, -0.05 - blade_len * 0.5), Vector3(-6, 0, 0))
	# tip
	_add(WBPrim.mesh_box(Vector3(blade_w * 0.7, 0.022, 0.05), STEEL), Vector3(0, 0.05, -0.05 - blade_len), Vector3(-22, 0, 0))

	# serration (M9) / fuller line (KA-BAR)
	if id == "M9_Bayonet":
		for i in range(4):
			_add(WBPrim.mesh_box(Vector3(blade_w + 0.004, 0.012, 0.012), STEEL_DARK),
				Vector3(0, 0.006 + i * 0.001, -0.10 - i * 0.03))
	elif id == "KA-BAR":
		_add(WBPrim.mesh_box(Vector3(blade_w + 0.003, 0.008, blade_len * 0.6), STEEL_DARK),
			Vector3(0, 0.028, -0.10 - blade_len * 0.25))

	# hand gripping the handle
	_add(WBPrim.mesh_box(Vector3(0.075, 0.085, 0.11), SKIN), Vector3(0.01, -0.02, 0.05))
	_add(WBPrim.mesh_box(Vector3(0.055, 0.06, 0.06), SKIN), Vector3(0.02, -0.05, 0.10))


func _add(mesh: MeshInstance3D, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	mesh.position = pos
	mesh.rotation_degrees += rot
	_root.add_child(mesh)
	return mesh


func play_attack() -> void:
	_attack_t = 0.24


func play_switch() -> void:
	_switch_t = _switch_dur


func play_inspect() -> void:
	_inspect_t = 1.4


func _process(delta: float) -> void:
	if _root == null:
		return
	_t += delta

	# inspect: slow spin to show the blade
	if _inspect_t > 0.0:
		_inspect_t -= delta
		var it: float = 1.0 - clampf(_inspect_t / 1.4, 0.0, 1.0)
		var ik: float = sin(it * PI)
		_root.rotation_degrees = Vector3(8.0 + 10.0 * ik, -12.0 - 260.0 * ik, 0.0)
		_root.position = Vector3(0.30, -0.30 + 0.02 * ik, -0.50)
		return

	# draw animation: knife flips in from the right
	if _switch_t > 0.0:
		_switch_t -= delta
		var st: float = 1.0 - clampf(_switch_t / _switch_dur, 0.0, 1.0)
		_root.rotation_degrees = Vector3(8.0 + sin(st * PI) * 30.0, -12.0 - (1.0 - st) * 150.0, 0.0)
		_root.position = Vector3(0.30 + (1.0 - st) * 0.20, -0.30 - (1.0 - st) * 0.25, -0.50)
		return

	if _attack_t > 0.0:
		_attack_t -= delta
		var t: float = 1.0 - clampf(_attack_t / 0.24, 0.0, 1.0)
		# stab forward + swing down
		_root.rotation_degrees = Vector3(8.0 - sin(t * PI) * 62.0, -12.0 + sin(t * PI) * 22.0, 0.0)
		_root.position = Vector3(0.30, -0.30, -0.50 - sin(t * PI) * 0.18)
	else:
		_root.rotation_degrees = Vector3(8.0 + sin(_t * 2.0) * 2.0, -12.0 + sin(_t * 1.5) * 3.0, 0.0)
		_root.position = Vector3(0.30, -0.30 + sin(_t * 1.8) * 0.004, -0.50)

extends StaticBody3D
## Range dummy: no AI, 100 HP, shows HP, auto-recovers after being destroyed.

var hp := 100.0
var _label: Label3D
var _torso: MeshInstance3D
var _respawn := 0.0
const MAX_HP := 100.0


func _ready() -> void:
	_build()


func _build() -> void:
	var body_col := Color(0.72, 0.68, 0.55)

	_torso = WBPrim.mesh_box(Vector3(0.7, 1.1, 0.28), body_col)
	_torso.position.y = 1.15
	add_child(_torso)

	var head := WBPrim.mesh_sphere(0.19, body_col)
	head.position.y = 1.9
	add_child(head)

	# bullseye on the chest
	var ring := WBPrim.mesh_sphere(0.11, Color(0.90, 0.20, 0.15))
	ring.position = Vector3(0, 1.25, -0.16)
	ring.scale = Vector3(1, 1, 0.3)
	add_child(ring)

	var base := WBPrim.mesh_box(Vector3(0.9, 0.1, 0.5), Color(0.30, 0.30, 0.32))
	base.position.y = 0.05
	add_child(base)

	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.9, 2.1, 0.4)
	col.shape = sh
	col.position.y = 1.05
	add_child(col)

	_label = Label3D.new()
	_label.text = "%d" % int(hp)
	_label.position = Vector3(0, 2.5, 0)
	_label.font_size = 56
	_label.pixel_size = 0.006
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.modulate = Color(1, 1, 1)
	add_child(_label)


func take_damage(amount: float) -> void:
	if _respawn > 0.0:
		return
	hp = maxf(hp - amount, 0.0)
	if _label:
		_label.text = "%d" % int(hp)
	if _torso:
		_torso.material_override = WBPrim.mat(Color(1, 0.4, 0.4), Color(1, 0.3, 0.3), 2.0)
		get_tree().create_timer(0.08).timeout.connect(_reset_flash)
	if hp <= 0.0:
		_respawn = 0.8
		if _label:
			_label.text = "击破"


func _process(delta: float) -> void:
	if _respawn > 0.0:
		_respawn -= delta
		if _respawn <= 0.0:
			hp = MAX_HP
			if _label:
				_label.text = "%d" % int(hp)


func _reset_flash() -> void:
	if _torso and is_inside_tree():
		_torso.material_override = WBPrim.mat(Color(0.72, 0.68, 0.55))

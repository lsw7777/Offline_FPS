extends CharacterBody3D
## Enemy: always hunts the player, walks with a limb animation, swings its arm
## when attacking, and shows a floating health bar. Procedural humanoid.

signal died(pos: Vector3)

const SPEED := 4.2
const ATTACK_RANGE := 2.0
const ATTACK_DMG := 12.0
const ATTACK_CD := 0.8
const GRAVITY := 22.0
const MAX_HP := 100.0

var hp := MAX_HP
var player: Node = null

var _attack_timer := 0.0
var _attack_anim := 0.0
var _walk_phase := 0.0
var _avoid_timer := 0.0
var _avoid_dir := Vector3.ZERO
var _torso: MeshInstance3D
var _hp_fill: MeshInstance3D
var _body_root: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D


func _ready() -> void:
	add_to_group("enemy")
	_build_body()
	_build_hp_bar()


func _build_body() -> void:
	var armor := Color(0.60, 0.17, 0.15)
	var armor_dark := Color(0.17, 0.17, 0.20)
	var skin := Color(0.80, 0.58, 0.46)
	var boot := Color(0.09, 0.09, 0.11)

	_body_root = Node3D.new()
	_body_root.name = "Body"
	add_child(_body_root)

	_torso = WBPrim.mesh_capsule(0.85, 0.27, armor)
	_torso.position.y = 1.30
	_body_root.add_child(_torso)

	var plate := WBPrim.mesh_box(Vector3(0.52, 0.42, 0.34), armor_dark)
	plate.position = Vector3(0, 1.36, -0.02)
	_body_root.add_child(plate)

	var waist := WBPrim.mesh_box(Vector3(0.36, 0.18, 0.28), armor_dark)
	waist.position.y = 1.02
	_body_root.add_child(waist)

	var neck := WBPrim.mesh_cyl(0.10, 0.07, skin)
	neck.position.y = 1.72
	_body_root.add_child(neck)

	var head := WBPrim.mesh_sphere(0.19, skin)
	head.position.y = 1.90
	_body_root.add_child(head)

	var helmet := WBPrim.mesh_sphere(0.215, armor_dark)
	helmet.position.y = 1.94
	helmet.scale = Vector3(1, 0.72, 1)
	_body_root.add_child(helmet)

	for s in [-1.0, 1.0]:
		var eye := WBPrim.mesh_sphere(0.045, Color(1, 0.2, 0.2), Color(1, 0.3, 0.3), 2.5)
		eye.position = Vector3(0.07 * s, 1.90, -0.17)
		_body_root.add_child(eye)
		var sh := WBPrim.mesh_sphere(0.14, armor_dark)
		sh.position = Vector3(0.30 * s, 1.55, 0)
		_body_root.add_child(sh)

	_arm_l = _make_limb(0.62, 0.085, skin, Vector3(-0.30, 1.55, 0))
	_arm_r = _make_limb(0.62, 0.085, skin, Vector3(0.30, 1.55, 0))
	for arm in [_arm_l, _arm_r]:
		var hand := WBPrim.mesh_sphere(0.09, skin)
		hand.position.y = -0.64
		arm.add_child(hand)

	var gun := WBPrim.mesh_box(Vector3(0.06, 0.10, 0.40), armor_dark)
	gun.position = Vector3(0, -0.66, -0.20)
	_arm_r.add_child(gun)

	_leg_l = _make_limb(0.80, 0.11, armor, Vector3(-0.14, 0.98, 0))
	_leg_r = _make_limb(0.80, 0.11, armor, Vector3(0.14, 0.98, 0))
	for leg in [_leg_l, _leg_r]:
		var b := WBPrim.mesh_box(Vector3(0.18, 0.12, 0.30), boot)
		b.position = Vector3(0, -0.84, -0.06)
		leg.add_child(b)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.height = 1.9
	cap.radius = 0.4
	col.shape = cap
	col.position.y = 0.95
	add_child(col)


func _build_hp_bar() -> void:
	var bg := _make_bar(0.94, 0.15, Color(0.0, 0.0, 0.0, 0.65), 1)
	bg.position = Vector3(0, 2.44, 0)
	add_child(bg)

	_hp_fill = _make_bar(0.88, 0.11, Color(0.25, 0.85, 0.25, 1.0), 2)
	_hp_fill.position = Vector3(0, 2.44, 0)
	add_child(_hp_fill)


func _make_bar(w: float, h: float, color: Color, prio: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	mi.mesh = qm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.no_depth_test = true
	m.render_priority = prio
	mi.material_override = m
	return mi


func _update_hp_bar() -> void:
	if _hp_fill == null:
		return
	var ratio: float = clampf(hp / MAX_HP, 0.0, 1.0)
	var qm := _hp_fill.mesh as QuadMesh
	if qm:
		qm.size.x = 0.88 * ratio
	var m := _hp_fill.material_override as StandardMaterial3D
	if m:
		m.albedo_color = Color(1.0 - ratio * 0.75, 0.25 + ratio * 0.6, 0.2, 1.0)


func _make_limb(length: float, radius: float, color: Color, pivot_pos: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pivot_pos
	var seg := WBPrim.mesh_capsule(length, radius, color)
	seg.position.y = -length * 0.5
	pivot.add_child(seg)
	_body_root.add_child(pivot)
	return pivot


func setup(p: Node) -> void:
	player = p


func _physics_process(delta: float) -> void:
	_attack_timer -= delta
	if player == null:
		var p = get_tree().get_first_node_in_group("player")
		if p:
			player = p
		else:
			return

	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	var move_dir := Vector3.ZERO
	if dist > ATTACK_RANGE:
		move_dir = to_player.normalized()
		if _avoid_timer > 0.0:
			move_dir = _avoid_dir
			_avoid_timer -= delta
		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED
		if to_player.length_squared() > 0.01:
			var tgt := Vector3(player.global_position.x, global_position.y, player.global_position.z)
			if tgt.distance_squared_to(global_position) > 0.01:
				look_at(tgt, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_timer <= 0.0:
			_attack_timer = ATTACK_CD
			_attack_anim = 0.32
			if player.has_method("take_damage"):
				player.take_damage(ATTACK_DMG)

	_animate(delta)

	var before := global_position
	move_and_slide()
	if _avoid_timer <= 0.0 and move_dir != Vector3.ZERO:
		var actual := global_position - before
		var expected := move_dir * SPEED * delta
		if expected.length() > 0.0001 and actual.length() < expected.length() * 0.35:
			var perp := Vector3(-move_dir.z, 0.0, move_dir.x)
			if randf() < 0.5:
				perp = -perp
			_avoid_dir = perp.normalized()
			_avoid_timer = 0.55


func _animate(delta: float) -> void:
	# attack swing overrides walk animation
	if _attack_anim > 0.0:
		_attack_anim -= delta
		var t: float = 1.0 - clampf(_attack_anim / 0.32, 0.0, 1.0)
		var swing: float = sin(t * PI) * 1.8
		if _arm_r:
			_arm_r.rotation.x = -swing
		if _arm_l:
			_arm_l.rotation.x = -swing * 0.5
		return

	var speed := Vector2(velocity.x, velocity.z).length()
	if speed > 0.2:
		_walk_phase += delta * 9.0
		var sw := sin(_walk_phase) * 0.55
		if _leg_l:
			_leg_l.rotation.x = sw
		if _leg_r:
			_leg_r.rotation.x = -sw
		if _arm_l:
			_arm_l.rotation.x = -sw * 0.6
		if _arm_r:
			_arm_r.rotation.x = sw * 0.6
		if _body_root:
			_body_root.position.y = absf(sin(_walk_phase * 2.0)) * 0.035
	else:
		_walk_phase = 0.0
		for limb in [_leg_l, _leg_r, _arm_l, _arm_r]:
			if limb:
				limb.rotation.x = lerpf(limb.rotation.x, 0.0, 0.2)
		if _body_root:
			_body_root.position.y = lerpf(_body_root.position.y, 0.0, 0.2)


func take_damage(amount: float) -> void:
	hp -= amount
	if _torso:
		_torso.material_override = WBPrim.mat(Color(1, 0.45, 0.45), Color(1, 0.3, 0.3), 2.0)
		get_tree().create_timer(0.08).timeout.connect(_reset_flash)
	_update_hp_bar()
	if hp <= 0.0:
		died.emit(global_position)
		queue_free()


func _reset_flash() -> void:
	if _torso and is_inside_tree():
		_torso.material_override = WBPrim.mat(Color(0.60, 0.17, 0.15))

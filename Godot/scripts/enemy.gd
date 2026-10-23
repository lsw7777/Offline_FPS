extends CharacterBody3D
## Procedural enemy: humanoid mesh + simple chase-and-attack AI + health.
## Red theme so it reads clearly against the environment.

signal died(pos: Vector3)

const SPEED := 3.2
const AGGRO_RANGE := 18.0
const ATTACK_RANGE := 1.9
const ATTACK_DMG := 10.0
const ATTACK_CD := 1.0
const GRAVITY := 20.0

var hp := 100.0
var player: Node = null
var _attack_timer := 0.0
var _torso: MeshInstance3D


func _ready() -> void:
	add_to_group("enemy")
	_build_body()


func _build_body() -> void:
	var skin := Color(0.80, 0.22, 0.20)
	var head_c := Color(0.86, 0.60, 0.50)
	var dark := Color(0.15, 0.15, 0.16)

	# torso
	_torso = WBPrim.mesh_capsule(1.0, 0.34, skin)
	_torso.position.y = 1.05
	add_child(_torso)

	# head
	var head := WBPrim.mesh_sphere(0.24, head_c)
	head.position.y = 1.80
	add_child(head)

	# eyes (front is -Z)
	var eye_l := WBPrim.mesh_sphere(0.05, Color(0.9, 0.2, 0.2), Color(1, 0.3, 0.3), 2.0)
	eye_l.position = Vector3(-0.08, 1.82, -0.20)
	add_child(eye_l)
	var eye_r := WBPrim.mesh_sphere(0.05, Color(0.9, 0.2, 0.2), Color(1, 0.3, 0.3), 2.0)
	eye_r.position = Vector3(0.08, 1.82, -0.20)
	add_child(eye_r)

	# arms
	for s in [-1.0, 1.0]:
		var arm := WBPrim.mesh_capsule(0.7, 0.09, skin)
		arm.position = Vector3(0.40 * s, 1.15, 0)
		arm.rotation_degrees = Vector3(0, 0, -12.0 * s)
		add_child(arm)
	# legs
	for s in [-1.0, 1.0]:
		var leg := WBPrim.mesh_capsule(0.8, 0.11, dark)
		leg.position = Vector3(0.13 * s, 0.5, 0)
		add_child(leg)

	# collision
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.height = 1.9
	cap.radius = 0.4
	col.shape = cap
	col.position.y = 0.95
	add_child(col)


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
	var dist := to_player.length()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	if dist < AGGRO_RANGE:
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		if dist > ATTACK_RANGE:
			var dir := to_player.normalized()
			velocity.x = dir.x * SPEED
			velocity.z = dir.z * SPEED
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			if _attack_timer <= 0.0:
				_attack_timer = ATTACK_CD
				if player.has_method("take_damage"):
					player.take_damage(ATTACK_DMG)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()


func take_damage(amount: float) -> void:
	hp -= amount
	if _torso:
		_torso.material_override = WBPrim.mat(Color(1, 0.4, 0.4), Color(1, 0.3, 0.3), 2.0)
		get_tree().create_timer(0.08).timeout.connect(_reset_flash)
	if hp <= 0.0:
		died.emit(global_position)
		queue_free()


func _reset_flash() -> void:
	if _torso and is_inside_tree():
		_torso.material_override = WBPrim.mat(Color(0.80, 0.22, 0.20))

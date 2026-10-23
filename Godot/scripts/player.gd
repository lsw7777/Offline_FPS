extends CharacterBody3D
## First-person controller. Recoil is applied as a decaying pitch/yaw offset on
## top of the mouse-driven aim, so the view kicks up then settles back.

const MOUSE_SENS := 0.0022
const SPEED_WALK := 5.0
const SPEED_SPRINT := 8.0
const SPEED_CROUCH := 2.5
const JUMP_VELOCITY := 4.5
const ACCEL := 14.0

signal health_changed(hp: float)
signal damaged
signal died

@onready var camera: Camera3D = $Camera3D

var hp := 100.0
var mouse_pitch := 0.0
var yaw := 0.0
var recoil_pitch_deg := 0.0
var recoil_yaw_deg := 0.0
var recover_deg_per_s := 9.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func take_damage(amount: float) -> void:
	hp = maxf(hp - amount, 0.0)
	health_changed.emit(hp)
	damaged.emit()
	if hp <= 0.0:
		died.emit()


func respawn(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	hp = 100.0
	health_changed.emit(hp)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * MOUSE_SENS
		mouse_pitch -= event.relative.y * MOUSE_SENS
		mouse_pitch = clampf(mouse_pitch, -1.5, 1.5)
		rotation.y = yaw
		camera.rotation.x = mouse_pitch + deg_to_rad(recoil_pitch_deg)
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	# recoil recovery (visual only; the aim point is the mouse)
	recoil_pitch_deg = move_toward(recoil_pitch_deg, 0.0, recover_deg_per_s * delta)
	recoil_yaw_deg = move_toward(recoil_yaw_deg, 0.0, recover_deg_per_s * delta)
	camera.rotation.x = mouse_pitch + deg_to_rad(recoil_pitch_deg)

	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := SPEED_WALK
	if Input.is_action_pressed("sprint"):
		speed = SPEED_SPRINT
	if Input.is_action_pressed("crouch"):
		speed = SPEED_CROUCH
	var target := dir * speed
	velocity.x = move_toward(velocity.x, target.x, ACCEL * delta)
	velocity.z = move_toward(velocity.z, target.z, ACCEL * delta)
	move_and_slide()


func apply_recoil(kick_v_deg: float, kick_h_deg: float, recover: float) -> void:
	recoil_pitch_deg += kick_v_deg
	recoil_yaw_deg += kick_h_deg
	recover_deg_per_s = recover

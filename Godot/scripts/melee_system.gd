extends Node
## Melee system: mode-aware (only active in melee mode). 1/2/3 switch knives,
## left click attacks. Damage/range/interval come from melee.json.

signal melee_changed(id: String, display: String)
signal melee_hit(id: String)

var melee := {}
var order: Array = []
var current_melee_id := ""
var cooldown := 0.0
var melee_mode := false
var ui_blocked := false

@onready var camera: Camera3D = get_node("../Camera3D")
@onready var player: CharacterBody3D = get_parent()
var melee_model = null


func _ready() -> void:
	melee = WBData.melee()
	order = melee.keys()
	melee_model = get_node_or_null("../Camera3D/MeleeModel")
	if order.size() > 0:
		equip(order[0])


func equip(id: String) -> void:
	if not melee.has(id):
		return
	current_melee_id = id
	cooldown = 0.0
	if melee_model and melee_model.has_method("build"):
		melee_model.build(melee[id])
	melee_changed.emit(id, melee[id]["display_name_zh"])


func on_mode_changed(is_melee: bool) -> void:
	melee_mode = is_melee
	if melee_model and melee_model.has_method("set_active"):
		melee_model.set_active(is_melee)


func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	if not melee_mode:
		return

	# 1/2/3 switch knives
	for i in range(mini(order.size(), 3)):
		if Input.is_action_just_pressed("weapon_%d" % (i + 1)):
			equip(order[i])

	if not ui_blocked and Input.is_action_just_pressed("fire"):
		attack()


func attack() -> void:
	if not melee_mode or cooldown > 0.0 or current_melee_id == "":
		return
	if get_viewport().gui_get_hovered_control() != null:
		return
	var m: Dictionary = melee[current_melee_id]
	cooldown = float(m["interval_s"])
	if melee_model and melee_model.has_method("play_attack"):
		melee_model.play_attack()

	var from := camera.global_position
	var fwd := -camera.global_transform.basis.z
	var to := from + fwd * float(m["range_m"])
	var space := player.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [player.get_rid()]
	var res := space.intersect_ray(q)
	if not res.is_empty():
		var collider: Object = res["collider"]
		if collider and collider.has_method("take_damage"):
			collider.take_damage(float(m["damage_light"]))
			melee_hit.emit(current_melee_id)

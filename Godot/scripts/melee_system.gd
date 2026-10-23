extends Node
## Melee = rhythm controller (docs 3.3). Greybox uses M9_Bayonet by default.

signal melee_hit(id: String)

var melee := {}
var current_melee_id := "M9_Bayonet"
var cooldown := 0.0

@onready var camera: Camera3D = get_node("../Camera3D")
@onready var player: CharacterBody3D = get_parent()


func _ready() -> void:
	melee = WBData.melee()


func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	if Input.is_action_just_pressed("melee"):
		attack()


func attack() -> void:
	if not melee.has(current_melee_id) or cooldown > 0.0:
		return
	var m: Dictionary = melee[current_melee_id]
	cooldown = float(m["interval_s"])

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

extends MeshInstance3D
## Ejected brass casing: manual ballistic integration, frees itself.

var vel := Vector3.ZERO
var spin := Vector3.ZERO
var life := 1.4


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	life -= delta
	vel.y -= 14.0 * delta
	global_position += vel * delta
	rotation += spin * delta
	if life <= 0.0:
		queue_free()

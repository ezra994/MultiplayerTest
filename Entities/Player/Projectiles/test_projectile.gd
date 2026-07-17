extends RigidBody3D

var direction: Vector3
var speed: float = 3.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apply_central_force(direction * speed)
	if is_multiplayer_authority():
		await get_tree().create_timer(3).timeout
		queue_free()

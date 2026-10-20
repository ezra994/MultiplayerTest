extends Node3D
const RAGDOLL = preload("uid://cf50dtf424d0i")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	return
	for i in range(100):
		var r= RAGDOLL.instantiate()
		add_child(r)
		r.global_position = Vector3(0, 10, 0)

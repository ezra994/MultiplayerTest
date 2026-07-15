extends RayCast3D
@onready var floor_sphere: CSGSphere3D = $FloorSphere


func _process(delta: float) -> void:
	floor_sphere.global_position = get_collision_point()
	#print(global_position.y - floor_sphere.global_position.y)

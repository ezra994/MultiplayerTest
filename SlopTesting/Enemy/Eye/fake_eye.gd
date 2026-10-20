extends Item

func start(hit_dir: Vector3, strength: float, hit_point: Vector3) -> void:
	await get_tree().physics_frame
	apply_impulse(hit_dir * strength, hit_point - global_position)

func pop_off(hit_dir: Vector3, strength: float, hit_point: Vector3) -> void:
	await get_tree().physics_frame
	apply_impulse(hit_dir * strength * .15, hit_point - global_position)

extends StaticBody3D
const FAKE_EYE = preload("uid://dc8gaqkvil16t")

func take_damage(damage: float, hit_dir: Vector3, strength: float, hit_point: Vector3) -> void:
	get_parent().take_damage(damage * 10, hit_dir, strength, hit_point)
	#explode(hit_dir, strength, hit_point)
	#get_parent().take_damage(damage * 3, hit_dir, strength, hit_point)

#func explode(hit_dir: Vector3, strength: float, hit_point: Vector3) -> void:
	#var e = FAKE_EYE.instantiate()
	#get_tree().current_scene.add_child(e)
	#e.global_transform = global_transform
	#e.start(hit_dir, strength, hit_point)
	#queue_free()
	
func pop(hit_dir: Vector3, strength: float, hit_point: Vector3) -> void:
	var e = FAKE_EYE.instantiate()
	get_tree().current_scene.add_child(e)
	e.global_transform = global_transform
	e.pop_off(hit_dir, strength, hit_point)
	queue_free()

extends Node3D
signal boughted

const FAKE_EYE = preload("uid://dc8gaqkvil16t")
const TEST = preload("uid://byhj7fp6p76bd")
const GUN = preload("uid://buoto3a6hj2wn")
const GUN_ITEM = preload("uid://d3wbp6sfvyht")
const GUN_ITEM_TWO = preload("uid://ccwabhhdjktuq")

func bought() -> void:
	print("WORKS")
	$AnimationPlayer.play("Open")
	loot()
	
func loot() -> void:
	if randi() % 2 == 0:
		spawn_gun()
	else:
		spawn_second_gun()

func spawn_gun() -> void:
	var gun = GUN_ITEM.instantiate()
	gun.item_data.throwable_scene = GUN_ITEM
	get_tree().current_scene.add_child(gun)
	gun.global_position = self.global_position
	gun.apply_impulse(Vector3(5, 10, 0))
	
func spawn_second_gun() -> void:
	var gun = GUN_ITEM_TWO.instantiate()
	gun.item_data.throwable_scene = GUN_ITEM_TWO
	get_tree().current_scene.add_child(gun)
	gun.global_position = self.global_position
	gun.apply_impulse(Vector3(5, 10, 0))

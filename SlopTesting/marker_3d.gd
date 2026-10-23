extends Marker3D

const FAKE_EYE = preload("uid://dc8gaqkvil16t")
const TEST = preload("uid://byhj7fp6p76bd")
const GUN = preload("uid://buoto3a6hj2wn")
const GUN_ITEM = preload("uid://d3wbp6sfvyht")

var time = .5
var timer = 0.0

func _ready() -> void:
	await get_tree().create_timer(.1).timeout
	spawn_gun()
	spawn_second_gun()
	#spawn_eye()
	
func _process(delta: float) -> void:
	return
	timer += delta
	if timer >= time:
		spawn_eye()
		timer -= time

func spawn_eye() -> void:

	var eye = FAKE_EYE.instantiate()
	var test = TEST
	eye.item_data = TEST
	get_tree().current_scene.add_child(eye)
	eye.global_position = self.global_position
	
	
const GUN_ITEM_TWO = preload("uid://ccwabhhdjktuq")

func spawn_gun() -> void:
	var gun = GUN_ITEM.instantiate()
	gun.item_data.throwable_scene = GUN_ITEM
	get_tree().current_scene.add_child(gun)
	gun.global_position = self.global_position
func spawn_second_gun() -> void:
	var gun = GUN_ITEM_TWO.instantiate()
	gun.item_data.throwable_scene = GUN_ITEM_TWO
	get_tree().current_scene.add_child(gun)
	gun.global_position = self.global_position

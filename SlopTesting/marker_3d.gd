extends Marker3D

const FAKE_EYE = preload("uid://dc8gaqkvil16t")
const TEST = preload("uid://byhj7fp6p76bd")
const GUN = preload("uid://buoto3a6hj2wn")
const GUN_ITEM = preload("uid://d3wbp6sfvyht")

var time = .5
var timer = 0.0

func _ready() -> void:
	spawn_eye()
	
func _process(delta: float) -> void:
	timer += delta
	if timer >= time:
		spawn_eye()
		timer -= time

func spawn_eye() -> void:
	var gun = GUN_ITEM.instantiate()
	gun.item_data.throwable_scene = GUN_ITEM
	get_tree().current_scene.add_child(gun)
	var eye = FAKE_EYE.instantiate()
	var test = TEST
	eye.item_data = TEST
	get_tree().current_scene.add_child(eye)
	eye.global_position = self.global_position

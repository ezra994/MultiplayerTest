extends Marker3D

const FAKE_EYE = preload("uid://dc8gaqkvil16t")
const TEST = preload("uid://byhj7fp6p76bd")

var time = 3
var timer = 0.0

func _ready() -> void:
	spawn_eye()
	
func _process(delta: float) -> void:
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

extends Move
class_name Slide_loop

var speed_mult = .8
var slide_start_time: float = 1.0

func check_relevance(input : InputPackage) -> String:
	if player.velocity.length() > 1 and ("crouch_walk" in input.actions or "crouch_idle" in input.actions):
		return "okay"
	return "crouch_idle"


func update(input : InputPackage, delta : float):
	player.velocity = velocity_by_input(input, delta)
	player.move_and_slide()

func on_enter_state():
	player.play("slide_loop")
	get_parent().get_parent().test()
	
func on_exit_state():
	print("!")
	get_parent().get_parent().test()


func velocity_by_input(input : InputPackage, delta : float) -> Vector3:
	var new_velocity = player.velocity
	new_velocity.x = new_velocity.move_toward(Vector3.ZERO, delta * 3).x
	new_velocity.z = new_velocity.move_toward(Vector3.ZERO, delta * 3).z

	if not player.is_on_floor():
		new_velocity.y -= data.gravity * delta
	
	return new_velocity

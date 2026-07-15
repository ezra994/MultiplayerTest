extends Move
class_name Walk

var speed_mult: float = 1.0

func on_enter_state():
	player.play("walk")
	
func check_relevance(input : InputPackage) -> String:
	input.actions.sort_custom(moves_priority_sort)
	if input.actions[0] == "walk":
		return "okay"
	return input.actions[0]
	
func update(input : InputPackage, delta : float):
	player.velocity = velocity_by_input(input, delta)
	player.move_and_slide()


func velocity_by_input(input : InputPackage, delta : float) -> Vector3:
	var new_velocity = player.velocity

	
	var direction = (player.transform.basis * Vector3(input.input_direction.x, 0, input.input_direction.y)).normalized()
	new_velocity.x = direction.x * data.movespeed * speed_mult
	new_velocity.z = direction.z * data.movespeed * speed_mult
	print(new_velocity)
	if not player.is_on_floor():
		new_velocity.y -= data.gravity * delta
	
	return new_velocity

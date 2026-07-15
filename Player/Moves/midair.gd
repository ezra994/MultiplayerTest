extends Move
class_name Midair


func check_relevance(input : InputPackage) -> String:
	if player.is_on_floor():
		input.actions.sort_custom(moves_priority_sort)
		return input.actions[0]
	
	return "okay"

func update(input : InputPackage, delta : float):
	player.velocity.y -= data.gravity * delta
	player.move_and_slide()

func on_enter_state():
	player.play("midair")

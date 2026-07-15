extends Move
class_name Jump

var jump_time: float = .7

func check_relevance(input : InputPackage) -> String:
	if works_longer_than(jump_time):
		print("MIDAIR")
		return "midair"
	if player.is_on_floor():
		input.actions.sort_custom(moves_priority_sort)
		return input.actions[0]
	return "okay"

func update(input : InputPackage, delta : float):
	player.velocity.y -= data.gravity * delta
	player.move_and_slide()

func on_enter_state():
	player.velocity.y += 15
	player.play("jump_start")

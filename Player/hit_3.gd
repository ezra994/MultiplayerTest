extends Move
class_name Hit3

const COMBO_TIMING := 1.0
const TRANSITION_TIMING := 1.5

func on_enter_state():
	player.play("double_hit")
	player.velocity = Vector3.ZERO
	
func check_relevance(input : InputPackage):
	check_combos(input)
	if works_longer_than(COMBO_TIMING) and has_queued_move:
		has_queued_move = false
		return queued_move
	elif works_longer_than(TRANSITION_TIMING):
		input.actions.sort_custom(moves_priority_sort)
		return input.actions[0]
	else:
		return "okay"

extends Move
class_name Idle

func on_enter_state():
	player.play("idle")
	
func check_relevance(input : InputPackage) -> String:
	input.actions.sort_custom(moves_priority_sort)
	return input.actions[0]
	

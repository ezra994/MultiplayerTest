extends Move
class_name Crouch_idle

func on_enter_state():
	player.play("crouch_idle")
	
func check_relevance(input : InputPackage) -> String:
	input.actions.sort_custom(moves_priority_sort)
	return input.actions[0]
	
func on_exit_state():
	get_parent().get_parent().test()

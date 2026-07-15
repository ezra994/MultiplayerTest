extends Move
class_name Slide_start


var slide_start_time: float = 1.0

func check_relevance(input : InputPackage) -> String:
	if works_longer_than(slide_start_time):
		return "slide_loop"
	else:
		return "okay"
	#if player.is_on_floor():
		#input.actions.sort_custom(moves_priority_sort)
		#return input.actions[0]
	#return "okay"

func update(input : InputPackage, delta : float):
	#player.velocity.y -= data.gravity * delta
	player.move_and_slide()

func on_enter_state():
	player.play("slide_start")
#	get_parent().get_parent().test()
	

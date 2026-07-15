extends Node
class_name Move

# all-move flags and variables here
var player : CharacterBody3D
var data: PlayerData 

var has_queued_move: bool = false
var queued_move: String = "NOPE!"
var enter_state_time : float

static var moves_priority : Dictionary = {
	"idle" : 1,
	"crouch_walk": 3,
	"crouch_idle": 1,
	"walk" : 2,
	"sprint": 3,
	"slide_start": 5,
	"slide_loop": 6,
	"midair": 10,
	"jump" : 10, # be generous to not edit this to much when sprint, dash, crouch etc are added
	"hit_1": 15,
	"hit_2": 15,
	"hit_3": 15,
}



static func moves_priority_sort(a : String, b : String):
	if moves_priority[a] > moves_priority[b]:
		return true
	else:
		return false


func check_relevance(input : InputPackage) -> String:
	print_debug("error, implement the check_relevance function on your state")
	return "error, implement the check_relevance function on your state"


func update(input : InputPackage, delta : float):
	pass

func on_enter_state():
	pass

func on_exit_state():
	pass

#Combat -- 

func check_combos(input : InputPackage):
	# works if only children we have are combos, use defined on ready array if not
	var available_combos = get_children()
	for combo : Combo in available_combos:
		if combo.is_triggered(input):
			has_queued_move = true
			queued_move = combo.triggered_move
			
#Time ----
func mark_enter_state():
	enter_state_time = Time.get_unix_time_from_system()

func get_progress() -> float:
	var now = Time.get_unix_time_from_system()
	return now - enter_state_time

func works_longer_than(time : float) -> bool:
	if get_progress() >= time:
		return true
	return false

func works_less_than(time : float) -> bool:
	if get_progress() < time: 
		return true
	return false

func works_between(start : float, finish : float) -> bool:
	var progress = get_progress()
	if progress >= start and progress <= finish:
		return true
	return false

extends Combo
@onready var hit_1: Hit1 = $".."

func _ready() -> void:
	triggered_move = "hit_2"

func is_triggered(input: InputPackage) -> bool:
	print(input.actions)
	if input.actions.has("hit_1") and hit_1.works_longer_than(.1):
		return true
	return false

extends Combo
@onready var hit_2: Hit2 = $".."


func _ready() -> void:
	triggered_move = "hit_3"

func is_triggered(input: InputPackage) -> bool:
	print(input.actions)
	if input.actions.has("hit_1") and hit_2.works_longer_than(.1):
		return true
	return false

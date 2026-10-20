extends Node3D

#@onready var gun_holder: Node3D = $"../../Head/GunHolder"
#var guns: Array[Node] = []
#var max_guns: int = 0
#
#var current_index: int = 0
#func _ready() -> void:
	#guns = gun_holder.get_children()
#
#func _input(_event: InputEvent) -> void:
	#if Input.is_action_just_pressed("LeftClick"):
		#guns[0].shoot()

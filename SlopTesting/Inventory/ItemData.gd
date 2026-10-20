extends Resource
class_name ItemData

@export var name: String = ""
enum HoldMode { HAND, GRAB }
@export var hold_mode := HoldMode.HAND
@export var throwable_scene: PackedScene
@export var scene: PackedScene
@export_multiline var description: String = ""
@export var stackable: bool = false
@export var texture: Texture
	
func use(_target: MultiPlayer) -> void:
	pass

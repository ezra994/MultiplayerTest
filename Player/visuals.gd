extends Node3D

@onready var model: PlayerModel = %Model
@onready var sphere_002: MeshInstance3D = $Sphere_002


func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	sphere_002.skeleton = model.skeleton.get_path()

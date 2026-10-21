extends Node3D

@onready var animation_player: AnimationPlayer = $HandsTesting2/AnimationPlayer

func shoot() -> float:
	animation_player.play("ShootPistol")
	return .5

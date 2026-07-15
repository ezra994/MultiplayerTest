extends CharacterBody3D

@onready var data: Node3D = %Data
@onready var visuals: Node3D = %Visuals
@onready var input_gatherer: Node3D = %InputGatherer
@onready var model: Node3D = %Model

func _physics_process(delta: float) -> void:
	var input = input_gatherer.gather_input()
	model.update(input, delta)
	input.queue_free()

func play(ani: String) -> void:
	model.play(ani)

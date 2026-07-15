extends Node3D
class_name InputGatherer

@onready var player: CharacterBody3D = $".."

func gather_input() -> InputPackage:
	var new_input = InputPackage.new()
	
	if Input.is_action_just_pressed("hit"):
		new_input.combat_actions.append("hit")
		
	if Input.is_action_just_pressed("Jump"):
		new_input.actions.append("jump")
	
	new_input.input_direction = Input.get_vector("Left", "Right", "Forward", "Backwards")
	if new_input.input_direction != Vector2.ZERO:
		new_input.actions.append("walk")
	
	if Input.is_action_pressed("Sprint") and new_input.input_direction != Vector2.ZERO: 
		new_input.actions.append("sprint")
	
	if !player.is_on_floor():
		new_input.actions.append("midair")
	
	if Input.is_action_pressed("Crouch"):
		if new_input.actions.has("sprint") and player.velocity.length() > 5 \
		and new_input.input_direction != Vector2.ZERO:
			new_input.actions.append("slide_start")
		elif new_input.input_direction != Vector2.ZERO:
			new_input.actions.append("crouch_walk")
		else:
			new_input.actions.append("crouch_idle")
		
		
	if new_input.actions.is_empty():
		new_input.actions.append("idle")
	
	return new_input

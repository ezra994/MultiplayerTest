extends CharacterBody3D
class_name MultiPlayer

@onready var looking_raycast: ShapeCast3D = $Head/LookingRaycast
@export var data: PlayerData
@export var visuals: Node3D
@export var input_gatherer: InputGatherer
@export var model: Node3D
@export var head: Node3D            # pivot node that holds the Camera3D
@export var mouse_sensitivity := 0.002
@export var max_pitch_deg := 89.0

@onready var unzoomed: Marker3D = $Head/Unzoomed
@onready var zoomed: Marker3D = $Head/Zoomed
@onready var item_holder: Node3D = $Head/ItemHolder

var zoom: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var input = input_gatherer.gather_input()
	model.update(input, delta)
	input.queue_free()

var recoil = 0.0
func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("Interact"):
		interact()
		
	if event.is_action_pressed("RightClick"):
		set_zoom(true)
	if event.is_action_released("RightClick"):
		set_zoom(false)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("LeftClick"):
		Global.cookies += 50
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#	else:

				#head.rotation.x,
				#deg_to_rad(-max_pitch_deg),
				#deg_to_rad(max_pitch_deg)
				#)
			#$Hands/HandsPlayer.play("nothing_idle_left")
	
	# Look around
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)   # yaw: turn the body
		head.rotate_x(-event.relative.y * mouse_sensitivity)  # pitch: tilt the head
		head.rotation.x = clampf(
			head.rotation.x,
			deg_to_rad(-max_pitch_deg),
			deg_to_rad(max_pitch_deg)
		)
		
	# Press Esc to free the mouse
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

var zoom_tween: Tween

func set_zoom(value: bool) -> void:
	zoom = value
	var target: Marker3D = zoomed if zoom else unzoomed
	var fov: float = 35 if zoom else 75

	# Stop any tween already running so they don't fight each other
	if zoom_tween and zoom_tween.is_valid():
		zoom_tween.kill()

	zoom_tween = create_tween()
	zoom_tween.set_parallel(true)
	zoom_tween.set_trans(Tween.TRANS_QUAD)
	zoom_tween.set_ease(Tween.EASE_OUT)
	zoom_tween.tween_property(item_holder, "position", target.position, 0.15)
	zoom_tween.tween_property(item_holder, "quaternion", target.quaternion, 0.15)
	zoom_tween.tween_property($Head/Camera3D, "fov", fov, 0.15)

func play(ani: String) -> void:
	model.play(ani)

func interact() -> void:
	if looking_raycast.is_colliding() and looking_raycast.get_collider(0) is Buyable:
		looking_raycast.get_collider(0).buy()

extends CharacterBody3D
@onready var camera_3d: Camera3D = %Camera3D
@export var steam_id: int = 0
@export var player_name: String 
@onready var player_name_label: Label3D = %PlayerNameLabel

const WALK_SPEED = 4.5
var SPEED = WALK_SPEED
const JUMP_VELOCITY = 4.5
var fall_distance = 0.0
var fall_start_y: float = 0.0
var slide_speed := 0.0
var can_slide: bool = false
var sliding: bool = false
var falling: bool = false
var sens := 0.001
@onready var slide_check: RayCast3D = $slide_check

var can_charge: float = 0.0
var gun_charge: float = 0.0
#Voice
var current_sample_rate: int = 40000
var local_playback: AudioStreamGeneratorPlayback = null
var voice_playback: AudioStreamGeneratorPlayback = null
@onready var voice_chat_test: AudioStreamPlayer3D = %VoiceChatTest

func _enter_tree() -> void:
	if is_multiplayer_authority():
		steam_id = SteamManager.STEAM_ID
		player_name = SteamManager.STEAM_USERNAME
		record_voice(true)
	else:
		var peer = SteamManager.peer
		var id: int = get_multiplayer_authority()
		steam_id = peer.get_steam_id_for_peer_id(id)
		player_name = Steam.getFriendPersonaName(steam_id)

func _ready() -> void:
	add_to_group("players")
	if is_multiplayer_authority(): 
		camera_3d.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	current_sample_rate = Steam.getVoiceOptimalSampleRate()
	voice_chat_test.stream.mix_rate = Steam.getVoiceOptimalSampleRate()
	voice_chat_test.play()
	voice_playback = voice_chat_test.get_stream_playback()
	player_name_label.text = player_name
	floor_snap_length = 5.0
	floor_max_angle = deg_to_rad(90)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	
	if can_charge and gun_charge <= 1.5: gun_charge += delta
		
	if sliding: $MeshInstance3D.rotation.x = deg_to_rad(40.0)
	else: $MeshInstance3D.rotation.x = 0.0


	if not is_on_floor():
		if not falling:
			falling = true
			fall_start_y = global_position.y
		velocity += get_gravity() * delta
	else:
		if falling:
			fall_distance = fall_start_y - global_position.y
			falling = false
			if sliding:
				slide_speed += fall_distance / 10
		else:
			fall_distance = 0.0

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if can_slide and Input.is_action_pressed("Crouch") and is_on_floor():
		slide()
	elif sliding:
		sliding = false
		can_slide = false
		SPEED = WALK_SPEED

	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()

func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return
	
	if event.is_action_pressed("hit"):
		gun_charge = 0.0
		can_charge = true
	if event.is_action_released("hit"):
		print(gun_charge)
		can_charge = false
		animate_gun()
		request_shoot()

	if Input.is_action_just_pressed("Crouch") and velocity.length() > 3 and is_on_floor() \
	and (Input.is_action_pressed("Forward") or (slide_check.is_colliding() and get_floor_angle() > deg_to_rad(15))):
		can_slide = true
	if Input.is_action_just_released("Crouch") or Input.is_action_just_released("Forward"):
		can_slide = false
		sliding = false
		SPEED = WALK_SPEED
	
	if event is InputEventMouseMotion:
		self.rotation.y -= event.relative.x * sens
		camera_3d.rotation.x -= event.relative.y * sens
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-30), deg_to_rad(15))
	
	if event.is_action_pressed("test_l"):
		$MeshInstance3D.rotation.z = deg_to_rad(50)
	
	if event.is_action_released("test_l"):
		$MeshInstance3D.rotation.z = deg_to_rad(0)
	
	if event.is_action_pressed("test_r"):
		$MeshInstance3D.rotation.z = deg_to_rad(-50)
	
	if event.is_action_released("test_r"):
		$MeshInstance3D.rotation.z = deg_to_rad(0)
		
func slide() -> void:
	if !sliding:
		if get_floor_angle() > .2:
			slide_speed = 15.0
			slide_speed += fall_distance / 10
		else:
			slide_speed = 10.0
	print(slide_speed)
	sliding = true

	if slide_check.is_colliding():
		slide_speed += get_floor_angle() / 10
	else:
		slide_speed -= (get_floor_angle() / 5) + 0.06

	if slide_speed < 0:
		slide_speed = 0
		can_slide = false
		sliding = false
		SPEED = WALK_SPEED
		return

	SPEED = slide_speed

@onready var marker_3d: Marker3D = $test_pistol/Marker3D
func request_shoot() -> void:
	if !is_multiplayer_authority():
		return

	SteamManager.shoot_ball.rpc_id(1, marker_3d.global_position, gun_charge * 500, -camera_3d.global_transform.basis.z) #1 is server


func _process(delta: float) -> void:
	check_for_voice()

func check_for_voice() -> void:
	var available_voice: Dictionary = Steam.getAvailableVoice()

	if available_voice['result'] == Steam.VoiceResult.VOICE_RESULT_OK and available_voice['size'] > 0:
		var voice_data: Dictionary = Steam.getVoice()

		if voice_data['result'] == Steam.VOICE_RESULT_OK and voice_data['size'] > 0:
			# Here we pass the voice data off to the network
			process_voice_data.rpc(voice_data['buffer'])

@rpc("any_peer", "call_remote", "unreliable")
func process_voice_data(voice_data: PackedByteArray) -> void:
	var decompressed_voice: Dictionary = Steam.decompressVoice(voice_data, current_sample_rate)

	if decompressed_voice['result'] == Steam.VoiceResult.VOICE_RESULT_OK and decompressed_voice['size'] > 0:
		var frames_to_push: PackedVector2Array = PackedVector2Array()
		frames_to_push.resize(decompressed_voice['size'] / 2)

		for i in range(0, decompressed_voice['size'], 2):
			var sample_int: int = decompressed_voice['uncompressed'].decode_s16(i)
			var amplitude: float = float(sample_int) / 32768.0
			frames_to_push[i / 2] = Vector2(amplitude,  amplitude)

		if voice_playback.get_frames_available() >= frames_to_push.size():
			voice_playback.push_buffer(frames_to_push)
		elif voice_playback.get_frames_available() > 0:
			voice_playback.push_buffer(frames_to_push.slice(0, voice_playback.get_frames_available()))

func record_voice(is_recording: bool) -> void:
	# If talking, suppress all other audio or voice comms from the Steam UI
	Steam.setInGameVoiceSpeaking(steam_id, is_recording)

	if is_recording:
		Steam.startVoiceRecording()
	else:
		Steam.stopVoiceRecording()

@onready var test_pistol: Node3D = $test_pistol
var tween: Tween
func animate_gun() -> void:
	if tween: tween.kill()
	test_pistol.rotation.x = deg_to_rad(0)
	tween = create_tween()
	tween.tween_property(test_pistol, "rotation", Vector3(deg_to_rad(360), test_pistol.rotation.y, test_pistol.rotation.z), .3).set_ease(Tween.EASE_IN_OUT)

extends CharacterBody3D
@onready var camera_3d: Camera3D = %Camera3D
@export var steam_id: int = 0
@export var player_name: String 
@onready var player_name_label: Label3D = %PlayerNameLabel

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

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
	if is_multiplayer_authority(): camera_3d.current = true
	current_sample_rate = Steam.getVoiceOptimalSampleRate()
	voice_chat_test.stream.mix_rate = Steam.getVoiceOptimalSampleRate()
	voice_chat_test.play()
	voice_playback = voice_chat_test.get_stream_playback()
	player_name_label.text = player_name

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
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
		request_shoot() 
		



func request_shoot() -> void:
	if !is_multiplayer_authority():
		return

	var pos = global_position + Vector3(0, 0, -4)
	SteamManager.shoot_ball.rpc_id(1, pos) #1 is server


	

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

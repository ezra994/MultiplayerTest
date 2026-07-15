extends CharacterBody3D
@onready var camera_3d: Camera3D = %Camera3D
@export var steam_id: int = 0
@export var player_name: String 
@onready var player_name_label: Label3D = %PlayerNameLabel

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

#Voice
var current_sample_rate: int = 40000
var has_loopback: bool = false
var local_playback: AudioStreamGeneratorPlayback = null
var network_playback: AudioStreamGeneratorPlayback = null

@onready var prox_network: AudioStreamPlayer3D = %ProxNetwork
@onready var prox_local: AudioStreamPlayer3D = %ProxLocal

func _ready() -> void:
	prox_local.stream.mix_rate = current_sample_rate
	prox_local.play()
	local_playback = prox_local.get_stream_playback()
	prox_network.stream.mix_rate = current_sample_rate
	prox_network.play()
	network_playback = prox_network.get_stream_playback()
	add_to_group("players")
	
	if is_multiplayer_authority():
		camera_3d.current = true
		steam_id = SteamManager.STEAM_ID
		player_name = SteamManager.STEAM_USERNAME
	else:
		var peer = SteamManager.peer
		var id: int = get_multiplayer_authority()
		steam_id = peer.get_steam_id_for_peer_id(id)
		player_name = Steam.getFriendPersonaName(steam_id)
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

# ---- VOICE: RPC based ----

# Called on the authority's own client after capturing mic input.
# rpc() with "call_remote" sends this to every other connected peer,
# but does NOT run locally on the sender (so no self-echo here).
@rpc("authority", "call_remote", "unreliable")
func receive_voice_data(voice_data: PackedByteArray) -> void:
	_play_voice(voice_data, network_playback)

func _play_voice(raw_buffer: PackedByteArray, playback_to_use: AudioStreamGeneratorPlayback) -> void:
	get_sample_rate()
	var decompressed_voice: Dictionary = Steam.decompressVoice(raw_buffer, current_sample_rate)
	
	if decompressed_voice['result'] == Steam.VOICE_RESULT_OK and decompressed_voice['uncompressed'].size() > 0:
		var voice_buffer = decompressed_voice['uncompressed']
		voice_buffer.resize(decompressed_voice['size'])
		var frames_available = playback_to_use.get_frames_available()
		
		for i in range(0, min(frames_available * 2, voice_buffer.size() - 1), 2):
			if i + 1 >= voice_buffer.size():
				break
			var raw_value: int = voice_buffer[i] | (voice_buffer[i + 1] << 8)
			raw_value = (raw_value + 32768) & 0xffff
			var amplitude: float = float(raw_value - 32768) / 32768.0
			playback_to_use.push_frame(Vector2(amplitude, amplitude))

func record_voice(is_recording: bool) -> void:
	Steam.setInGameVoiceSpeaking(SteamManager.STEAM_ID, is_recording)
	if is_recording:
		Steam.startVoiceRecording()
	else:
		Steam.stopVoiceRecording()

func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return
	if event.is_action_pressed("voice_record"):
		record_voice(true)
	elif event.is_action_released("voice_record"):
		record_voice(false)

func _process(delta: float) -> void:
	if is_multiplayer_authority():
		check_for_voice()

func check_for_voice() -> void:
	var available_voice: Dictionary = Steam.getAvailableVoice()
	if available_voice["result"] == Steam.VOICE_RESULT_OK and available_voice["size"] > 0:
		var voice_data: Dictionary = Steam.getVoice()
		if voice_data["result"] == Steam.VOICE_RESULT_OK:
			rpc("receive_voice_data", voice_data["buffer"])
			
			if has_loopback:
				_play_voice(voice_data["buffer"], local_playback)

func get_sample_rate(is_toggled: bool = true) -> void:
	if is_toggled:
		current_sample_rate = Steam.getVoiceOptimalSampleRate()
	else:
		current_sample_rate = 48000
	prox_local.stream.mix_rate = current_sample_rate
	prox_network.stream.mix_rate = current_sample_rate

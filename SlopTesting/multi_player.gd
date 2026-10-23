extends CharacterBody3D
class_name MultiPlayer

@export var steam_id: int = 0
@export var player_name: String 
@onready var player_name_label: Label3D = %PlayerNameLabel

@onready var voice_chat: AudioStreamPlayer3D = %VoiceChat
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
@onready var camera_3d: Camera3D = $Head/Camera3D
var current_sample_rate: int = 40000
var local_playback: AudioStreamGeneratorPlayback = null
var voice_playback: AudioStreamGeneratorPlayback = null
@onready var voice_chat_test: AudioStreamPlayer3D = %VoiceChatTest
const PREBUFFER_SEC := 0.1
const MAX_QUEUE_SEC := 0.5

var pending := PackedVector2Array()
var buffering := true
var buffer_frames := 0
var zoom: bool = false

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
		
func _exit_tree() -> void:
	if is_multiplayer_authority():
		record_voice(false)
		
func _ready() -> void:
	if is_multiplayer_authority(): 
		camera_3d.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	current_sample_rate = Steam.getVoiceOptimalSampleRate()
	var gen := voice_chat.stream as AudioStreamGenerator
	gen.mix_rate = current_sample_rate
	gen.buffer_length = 0.25
	buffer_frames = int(gen.buffer_length * current_sample_rate)
	voice_chat.play()
	voice_playback = voice_chat.get_stream_playback()

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	var input = input_gatherer.gather_input()
	model.update(input, delta)
	input.queue_free()

var recoil = 0.0
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	
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

func _process(delta: float) -> void:
	if is_multiplayer_authority():
		check_for_voice()
	else:
		pump_playback()

func check_for_voice() -> void:
	var available := Steam.getAvailableVoice()
	if available["result"] != Steam.VOICE_RESULT_OK or available["size"] <= 0:
		return
	var voice_data := Steam.getVoice()
	if voice_data["result"] == Steam.VOICE_RESULT_OK and voice_data["size"] > 0:
		process_voice_data.rpc(voice_data["buffer"])

@rpc("any_peer", "call_remote", "unreliable_ordered", 2)  # own channel so it doesn't block game traffic
func process_voice_data(voice_data: PackedByteArray) -> void:
	var d := Steam.decompressVoice(voice_data, current_sample_rate)
	if d["result"] != Steam.VOICE_RESULT_OK or d["size"] <= 0:
		return
	var pcm: PackedByteArray = d["uncompressed"]
	var count: int = d["size"] / 2
	var frames := PackedVector2Array()
	frames.resize(count)
	for i in count:
		var a := pcm.decode_s16(i * 2) / 32768.0
		frames[i] = Vector2(a, a)
	pending.append_array(frames)

	# Cap latency if we fall behind
	var max_frames := int(MAX_QUEUE_SEC * current_sample_rate)
	if pending.size() > max_frames:
		pending = pending.slice(pending.size() - max_frames)

func pump_playback() -> void:
	if voice_playback == null:
		return
	var room := voice_playback.get_frames_available()
	var buffered := (buffer_frames - room) + pending.size()

	if buffering:
		if buffered < int(PREBUFFER_SEC * current_sample_rate):
			return
		buffering = false
	elif buffered == 0:
		buffering = true
		return

	var n := mini(room, pending.size())
	if n > 0:
		voice_playback.push_buffer(pending.slice(0, n))
		pending = pending.slice(n)

func record_voice(is_recording: bool) -> void:
	# If talking, suppress all other audio or voice comms from the Steam UI
	Steam.setInGameVoiceSpeaking(steam_id, is_recording)

	if is_recording:
		Steam.startVoiceRecording()
	else:
		Steam.stopVoiceRecording()

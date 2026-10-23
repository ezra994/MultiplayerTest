extends Node

signal spawn_host
signal setup

var STEAM_APP_ID: int = 480
var STEAM_USERNAME: String = ""
var STEAM_ID: int = 0

var is_lobby_host: bool = false
var lobby_id: int = 0
var invite_lobby_id: int = 0
var lobby_members: Array
 
var peer = SteamMultiplayerPeer.new()

func _init() -> void:
	OS.set_environment("SteamAppId", str(STEAM_APP_ID))
	OS.set_environment("SteamGameId", str(STEAM_APP_ID))

func _ready() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx( 480, true )
	print("Did Steam initialize?: %s " % initialize_response)
	print("Check steam initalizing")
	STEAM_ID = Steam.getSteamID()
	STEAM_USERNAME = Steam.getPersonaName()
	Steam.lobby_joined.connect(_on_lobby_joined)
	multiplayer.peer_connected.connect(func(_id): get_lobby_members())
	multiplayer.peer_disconnected.connect(func(_id): get_lobby_members())
	
	Steam.join_requested.connect(_on_lobby_join_requested)
	
#func _process(_delta: float) -> void:
	#Steam.run_callbacks()

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if is_lobby_host:
		return 
		
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		peer.connect_to_lobby(this_lobby_id)
		multiplayer.multiplayer_peer = peer
		setup.emit()
		get_lobby_members()
		
		if multiplayer.is_server():
			spawn_host.emit()

func get_lobby_members():
	lobby_members.clear()
	var num_of_lobby_members: int = Steam.getNumLobbyMembers(lobby_id)
	for member in range(0, num_of_lobby_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		lobby_members.append({
			"steam_id": member_steam_id,
			"steam_name": member_steam_name
		})

func _on_lobby_join_requested(lobby_id: int, friend_id: int) -> void:
	# Get name of the friend who invited the player or who they joined via the friends list
	var friend_joining: String = Steam.getFriendPersonaName(friend_id)

	print("Joining lobby with..." % friend_joining)

	Steam.joinLobby(lobby_id)

	# Alternatively, change scenes to the lobby manager and set this lobby ID in our global
	# script and remove the above call to Steam.joinLobby()
	invite_lobby_id = lobby_id
	
var projectile_spawn_container: Node3D
const TEST_PROJECTILE = preload("uid://c3im7dphtwp4e")
@rpc("any_peer", "call_local")
func shoot_ball(pos: Vector3, force: float, dir) -> void:
	if not multiplayer.is_server(): return
	var new_ball = TEST_PROJECTILE.instantiate()
	#new_ball.source = multiplayer.get_remote_sender_id()
	new_ball.speed = force
	new_ball.position = pos
	new_ball.direction = dir
	projectile_spawn_container.add_child(new_ball, true)

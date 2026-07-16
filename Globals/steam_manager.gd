extends Node

signal spawn_host
signal setup

var STEAM_APP_ID: int = 480
var STEAM_USERNAME: String = ""
var STEAM_ID: int = 0

var is_lobby_host: bool = false
var lobby_id: int
var lobby_members: Array
 
var peer = SteamMultiplayerPeer.new()

func _init() -> void:
	OS.set_environment("SteamAppId", str(STEAM_APP_ID))
	OS.set_environment("SteamGameId", str(STEAM_APP_ID))

func _ready() -> void:
	var init_result: Dictionary = Steam.steamInitEx()
	STEAM_ID = Steam.getSteamID()
	STEAM_USERNAME = Steam.getPersonaName()
	Steam.lobby_joined.connect(_on_lobby_joined)
	multiplayer.peer_connected.connect(func(_id): get_lobby_members())
	multiplayer.peer_disconnected.connect(func(_id): get_lobby_members())
	
func _process(delta: float) -> void:
	Steam.run_callbacks()

func _on_lobby_joined(this_lobby_id: int, permissions: int, locked: bool, response: int) -> void:
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
			print("W")

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
	

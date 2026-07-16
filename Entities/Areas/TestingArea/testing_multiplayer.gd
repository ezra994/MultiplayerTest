extends Node3D

@onready var multiplayer_ui: Control = %MultiplayerUi
@onready var lobbies_list: VBoxContainer = %LobbiesList
@onready var player_spawner: MultiplayerSpawner = %PlayerSpawner
@onready var spawn_container: Node3D = %SpawnContainer

var lobby_created: bool = false
var lobby_id: int = 0
var peer: SteamMultiplayerPeer

func _ready() -> void:
	SteamManager.projectile_spawn_container = spawn_container
	peer = SteamManager.peer
	Steam.lobby_created.connect(_on_lobby_created) 
	Steam.lobby_match_list.connect(get_lobby_match_list)
	
func _on_join_pressed() -> void:
	var lobbies_btns = lobbies_list.get_children()
	for i in lobbies_btns:
		i.queue_free()
	
	open_lobby_list() 

func open_lobby_list() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListStringFilter("game_id", "SexSexMungus", Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()
		
func get_lobby_match_list(lobbies: Array) -> void:
	for lobby in lobbies:

		var lobby_name = Steam.getLobbyData(lobby, "name")
		var members = Steam.getNumLobbyMembers(lobby)
		var max_members = Steam.getLobbyMemberLimit(lobby)
		
		var button := Button.new()
		button.set_text("{0} | {1}/{2}".format([lobby_name, members, max_members]))
		button.set_size(Vector2(400, 50))
		button.pressed.connect(join_lobby.bind(lobby))
		lobbies_list.add_child(button)
		
func join_lobby(_lobby_id: int) -> void:
	lobby_id = _lobby_id
	Steam.joinLobby(_lobby_id)
	hide_menu()

func _on_host_pressed() -> void:
	if lobby_created: return
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 16)
	hide_menu()
	
func _on_lobby_created(connect: int, _lobby_id: int) -> void:
	if connect:
		lobby_id = _lobby_id
		lobby_created = true
		Steam.setLobbyData(lobby_id, "name", str(SteamManager.STEAM_USERNAME))
		Steam.setLobbyData(lobby_id, "game_id", "SexSexMungus")
		Steam.setLobbyJoinable(lobby_id, true)
		SteamManager.lobby_id = lobby_id
		SteamManager.is_lobby_host = true
		
		peer.host_with_lobby(lobby_id)
		multiplayer.multiplayer_peer = peer
		player_spawner.setup()
		player_spawner.spawn_host()
		
func hide_menu() -> void:
	multiplayer_ui.visible = false

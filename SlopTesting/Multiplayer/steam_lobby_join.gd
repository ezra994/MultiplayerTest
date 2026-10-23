extends Control
const LOBBY_ENTRY = preload("uid://b8qiilmm0r1hy")

@onready var refresh: Button = $MarginContainer/VBoxContainer/HBoxContainer/Refresh
@onready var close: Button = $MarginContainer/VBoxContainer/HBoxContainer/Close

func _ready() -> void:
	refresh.pressed.connect(_on_refresh_pressed)
	Steam.lobby_match_list.connect(_on_lobby_match_list)

func _on_refresh_pressed() -> void:
	_add_request_lobby_filters()
	Steam.requestLobbyList()

func _add_request_lobby_filters() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LobbyDistanceFilter.LOBBY_DISTANCE_FILTER_DEFAULT)
	Steam.addRequestLobbyListFilterSlotsAvailable(1)
	Steam.addRequestLobbyListResultCountFilter(50)

				
func _on_lobby_match_list(these_lobbies: Array) -> void:
	if these_lobbies.size() == 0:
		print("No lobbies were found")
		return

	for this_lobby in these_lobbies:
		var lobby_object := LOBBY_ENTRY.instantiate()
		lobby_object.name = "Lobby%s" % this_lobby
		lobby_object.set_lobby_id(this_lobby)
		#lobby_object.joining_lobby.connect(_on_joining_lobby)
		#_lobby_list.call_deferred("add_child", lobby_object)

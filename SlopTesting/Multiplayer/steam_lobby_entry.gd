extends HBoxContainer

@onready var name_label: Label = $Name
@onready var join: Button = $Join
signal joining_lobby

var lobby_id: int = 0 : set = set_lobby_id
var lobby_name: String = "" : set = set_lobby_name

func _ready() -> void:
	_connect_signals()
	
#region Signals
func _connect_signals() -> void:
	join.pressed.connect(_on_pressed)


func _on_pressed() -> void:
	joining_lobby.emit(lobby_id)


# The setter for lobby ID which attempts to get the lobby name when set.
func set_lobby_id(new_lobby_id: int) -> void:
	lobby_id = new_lobby_id
	lobby_name = Steam.getLobbyData(lobby_id, "lobby_name")


# The setter for lobby name which will default to just the lobby ID if no valid
# name is passed to it.
func set_lobby_name(new_name: String) -> void:
	lobby_name = new_name
	if not is_node_ready(): await ready
	name_label.text = "Lobby %s" % lobby_id if lobby_name.is_empty() else lobby_name
#endregion

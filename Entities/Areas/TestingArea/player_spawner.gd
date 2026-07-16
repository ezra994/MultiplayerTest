extends MultiplayerSpawner
@export var player_scene: PackedScene
var players = {}

func _ready() -> void:
	spawn_function = spawn_player
	if !SteamManager.setup.is_connected(setup):
		SteamManager.setup.connect(setup)
# Call this manually right after multiplayer.multiplayer_peer is assigned
func setup() -> void:
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(spawn)
		multiplayer.peer_disconnected.connect(remove_player)

func spawn_host() -> void:
	if multiplayer.is_server():
		spawn(1)

func spawn_player(data) -> Node3D:
	var p = player_scene.instantiate()
	p.set_multiplayer_authority(data)
	players[data] = p
	return p

func remove_player(data) -> void:
	if players.has(data):
		players[data].queue_free()
		players.erase(data)

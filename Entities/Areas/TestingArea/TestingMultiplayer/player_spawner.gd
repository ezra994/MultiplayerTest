extends MultiplayerSpawner
@export var player_scene: PackedScene
var players = {}

func _ready() -> void:
	spawn_function = spawn_player
	if !SteamManager.setup.is_connected(setup):
		SteamManager.setup.connect(setup)

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
const GUN_ITEM_TWO = preload("uid://ccwabhhdjktuq")
const GUN_ITEM = preload("uid://d3wbp6sfvyht")

func spawn_gun() -> void:
	var gun = GUN_ITEM.instantiate()
	gun.item_data.throwable_scene = GUN_ITEM
	get_tree().current_scene.add_child(gun)
	gun.global_position = self.global_position
	gun.apply_impulse(Vector3(5, 10, 0))
	
func spawn_second_gun() -> void:
	var gun = GUN_ITEM_TWO.instantiate()
	gun.item_data.throwable_scene = GUN_ITEM_TWO
	get_tree().current_scene.add_child(gun)
	gun.global_position = self.global_position
	gun.apply_impulse(Vector3(5, 10, 0))

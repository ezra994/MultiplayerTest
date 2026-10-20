extends CharacterBody3D

@onready var spring: SpringBoneSimulator3D = $metarig/GeneralSkeleton/SpringBoneSimulator3D

@export var move_speed := 5.0
@export var accel := 8.0
@export var wind_strength := 0.5
@export var wind_interval := 5.0
@export var movement_speed: float = 4.0
@onready var navigation_agent: NavigationAgent3D = get_node("NavigationAgent3D")
var player: Node3D
const RAGDOLL = preload("uid://cf50dtf424d0i")

var t := 0.0
var wind_timer := 0.0
var target_wind := Vector3.ZERO
var current_wind := Vector3.ZERO

func _physics_process(delta: float) -> void:
	t += delta
	wind_timer += delta

	# Pick a new horizontal wind direction (no vertical push)
	if wind_timer >= wind_interval:
		wind_timer -= wind_interval
		var dir := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		target_wind = dir * wind_strength * randf_range(0.5, 1.0)

	# Ease toward the new wind instead of snapping
	current_wind = current_wind.lerp(target_wind, 1.0 - exp(-2.0 * delta))

	# Gust stays positive (0.7 to 1.3), so it never reverses direction
	var gust := 1.0 + 0.3 * sin(t * 2.0)
	spring.external_force = current_wind * gust

	if player == null:
		return
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return

	# Set the target BEFORE checking if navigation is finished
	navigation_agent.target_position = player.global_position

	if navigation_agent.is_navigation_finished():
		return

	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var new_velocity: Vector3 = global_position.direction_to(next_path_position) * movement_speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)



func _ready() -> void:
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	await get_tree().physics_frame
	player = get_tree().get_first_node_in_group("player")

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
	move_and_slide()

func die(hit_dir: Vector3, strength: float, hit_point: Vector3) -> void:
	var r = RAGDOLL.instantiate()
	get_tree().current_scene.add_child(r)
	r.global_transform = global_transform
	r.start(%GeneralSkeleton, hit_dir, hit_point, strength, velocity)
	queue_free()

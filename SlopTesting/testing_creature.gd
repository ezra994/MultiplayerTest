extends CharacterBody3D
class_name Enemy

var health: float = 10.0
const EYE = preload("uid://brdehayx14jls")

var eyes: Array

@export var movement_speed: float = 4.0
@export var turn_speed: float = 8.0
@export var gravity: float = 20.0
@export var model_yaw_offset: float = 0.0  # set to PI if your model faces +Z instead of -Z
@export var repath_interval: float = 0.3
@export var path_end_stop_distance: float = 0.6  # stop when this close to the end of the path

@onready var navigation_agent: NavigationAgent3D = get_node("NavigationAgent3D")
var player: Node3D
var dead: bool = false
var _repath_timer: float = 0.0

func _ready() -> void:
	place_eyes()
	navigation_agent.link_reached.connect(_on_link_reached)
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	await get_tree().physics_frame
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if dead:
		return

	# Gravity always applies, even if there's no target/nav yet
	if not is_on_floor():
		velocity.y -= gravity * delta

	if not is_instance_valid(player):
		_stop_and_slide()
		return

	var map: RID = navigation_agent.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		_stop_and_slide()
		return

	# Repath on a timer instead of every frame
	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = repath_interval
		navigation_agent.target_position = player.global_position

	# Calling this updates the path
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()

	# Stop if there's no usable path, or we've reached the end of it
	var path: PackedVector3Array = navigation_agent.get_current_navigation_path()
	var at_path_end := false
	if path.size() > 0:
		var flat_end: Vector3 = path[path.size() - 1]
		flat_end.y = global_position.y
		at_path_end = global_position.distance_to(flat_end) < path_end_stop_distance

	if path.size() < 2 or at_path_end or navigation_agent.is_navigation_finished():
		_stop_and_slide()
		_face_position(player.global_position, delta)
		return

	var direction: Vector3 = global_position.direction_to(next_path_position)
	direction.y = 0.0  # keep movement horizontal; gravity handles vertical
	direction = direction.normalized()

	var new_velocity: Vector3 = direction * movement_speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

	_face_position(player.global_position, delta)

func _stop_and_slide() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if dead:
		return
	# Preserve vertical velocity (gravity); only take horizontal from avoidance
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	move_and_slide()

func _face_position(target: Vector3, delta: float) -> void:
	var to_target: Vector3 = target - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.001:
		return
	var target_yaw: float = atan2(-to_target.x, -to_target.z) + model_yaw_offset
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))

func _on_link_reached(details: Dictionary) -> void:
	# Don't teleport. The zombie walks across links on its own.
	# Use this only for special behavior, e.g. bashing a door.
	var link := details.get("owner") as NavigationLink3D
	if link == null:
		return
	var door := link.get_parent()
	if door != null and door.has_method("zombie_interact"):
		door.zombie_interact(self)

func take_damage(damage: float, hit_dir: Vector3, strength: float, hit_point: Vector3) -> void:
	if dead:
		return
	health -= damage
	if health <= 0:
		die(hit_dir, strength, hit_point)

func die(hit_dir: Vector3, strength: float, hit_point: Vector3) -> void:
	if dead:
		return
	dead = true
	set_physics_process(false)
	navigation_agent.avoidance_enabled = false
	spawn_ragdoll(hit_dir, strength, hit_point)
	pop_eyes(hit_dir, strength, hit_point)
	queue_free()

func spawn_ragdoll(hit_dir: Vector3, strength: float, hit_point: Vector3) -> void:
	pass
#	var r = RAGDOLL.instantiate()
#	get_tree().current_scene.add_child(r)
	#r.global_transform = global_transform
#	r.start(%GeneralSkeleton, hit_dir, hit_point, strength, velocity)

func pop_eyes(hit_dir: Vector3, strength: float, hit_point: Vector3) -> void:
	for eye in eyes:
		if not is_instance_valid(eye):
			continue
		eye.pop(hit_dir, strength, hit_point)
		
@onready var cube: MeshInstance3D = $metarig/GeneralSkeleton/Cube
func place_eyes() -> void:
	for i in randi_range(3, 10):
		var e = EYE.instantiate()
		add_child(e)
		eyes.append(e)
		e.position = $metarig/GeneralSkeleton/Cube/Marker3D.position + Vector3(randf_range(-.5, .5), randf_range(-.5, .5), randf_range(-.5, .5))

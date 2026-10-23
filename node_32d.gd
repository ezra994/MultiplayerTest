extends RigidBody3D
class_name Ragdoll

@export var ragdoll_time := 3.0
@export var return_time := 0.8
@export var launch_strength := 8.0
@export var launch_up := 4.0
@export var spin_strength := 1.5
@export var hips_bone_name := "Hips"

@export_group("Chase")
@export var chase_enabled := true
@export var move_speed := 15.0
@export var acceleration := 30.0        # max horizontal accel (m/s²)
@export var stop_distance := 0.8        # stop this close to the player
@export var repath_interval := 0.3
@export var model_yaw_offset := 0.0     # PI if the model faces +Z

@export_group("Balance")
@export var upright_stiffness := 60.0   # how hard it springs back to the target orientation
@export var upright_damping := 12.0     # stops it oscillating
@export var max_torque_accel := 80.0    # rad/s² cap, so big hits can still knock it over

@onready var general_skeleton: Skeleton3D = %GeneralSkeleton
@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $GeneralSkeleton/PhysicalBoneSimulator3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

enum State { ACTIVE, RAGDOLL, RECOVERING }
var _state := State.ACTIVE
var _recover_tween: Tween

var _timer := Timer.new()

const ANIM_NAME := "Armature_001|mixamo_com|Layer0"

var _bones: Array[PhysicalBone3D] = []
var _local_targets: Array[Transform3D] = []
var _targets: Array[Transform3D] = []
var _starts: Array[Transform3D] = []
var _hips_index := 0
var _ragdolling := false
var _rest_y := 0.0

var player: Node3D
var _setup_done := false
var _repath_timer := 0.0
var _desired_velocity := Vector3.ZERO
var _look_dir := Vector3.FORWARD

func _ready() -> void:
	_timer.one_shot = true
	_timer.timeout.connect(deactivate_ragdoll)
	add_child(_timer)
	can_sleep = false   # a sleeping body would stop reacting to the controller

	for c in physical_bone_simulator_3d.get_children():
		var pb := c as PhysicalBone3D
		if pb == null:
			continue
		if pb.bone_name == hips_bone_name:
			_hips_index = _bones.size()
		_bones.append(pb)

	physical_bone_simulator_3d.physical_bones_add_collision_exception(get_rid())

	animation_player.play(ANIM_NAME)
	animation_player.seek(0.0, true)
	animation_player.pause()
	await get_tree().physics_frame
	await get_tree().physics_frame

	var inv := global_transform.affine_inverse()
	for b in _bones:
		_local_targets.append(inv * b.global_transform)
	_rest_y = global_position.y

	# Keep animating while chasing; activate_ragdoll() stops it
	animation_player.play(ANIM_NAME)
	_setup_done = true

	#await get_tree().create_timer(0.5).timeout
	#var impulse := -global_transform.basis.z * launch_strength + Vector3.UP * launch_up
	#activate_ragdoll(impulse)

	#await get_tree().create_timer(ragdoll_time).timeout
	#deactivate_ragdoll()

func _physics_process(delta: float) -> void:
	if _state == State.RAGDOLL:
		global_position = _root_pos_under_hips()
		return
	if _state == State.ACTIVE:
		_update_chase(delta)

# Decides WHERE to go. Runs in _physics_process because the NavigationAgent likes it there.
func _update_chase(delta: float) -> void:
	_desired_velocity = Vector3.ZERO
	if not chase_enabled or not _setup_done:
		return

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	var map: RID = navigation_agent.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return

	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = repath_interval
		navigation_agent.target_position = player.global_position

	# Always face the player, even when standing still
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() > 0.001:
		_look_dir = to_player.normalized()

	var next_pos := navigation_agent.get_next_path_position()
	if navigation_agent.is_navigation_finished() or to_player.length() < stop_distance:
		return

	var dir := next_pos - global_position
	dir.y = 0.0
	if dir.length_squared() > 0.0001:
		_desired_velocity = dir.normalized() * move_speed

# Applies the forces. Runs inside the physics step so it can use the body state directly.
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _state != State.ACTIVE or freeze:
		return

	# --- Movement: steer horizontal velocity toward the desired one ---
	var v := state.linear_velocity
	var flat_v := Vector3(v.x, 0.0, v.z)
	var accel_vec := ((_desired_velocity - flat_v) * 10.0).limit_length(acceleration)
	state.apply_central_force(accel_vec * mass)

	# --- Balance: spring-damper torque toward "upright and facing the player" ---
	var target_basis := Basis.looking_at(_look_dir, Vector3.UP) * Basis(Vector3.UP, model_yaw_offset)
	var q_cur := state.transform.basis.get_rotation_quaternion()
	var q_err := target_basis.get_rotation_quaternion() * q_cur.inverse()
	if q_err.w < 0.0:
		q_err = -q_err   # take the short way around
	var err := Vector3(q_err.x, q_err.y, q_err.z) * 2.0   # ~ axis * angle for small errors

	var ang_accel := (err * upright_stiffness - state.angular_velocity * upright_damping)
	ang_accel = ang_accel.limit_length(max_torque_accel)

	# Scale by the inertia tensor so the same tuning works for any body size/mass
	var inertia := state.inverse_inertia_tensor.inverse()
	state.apply_torque(inertia * ang_accel)

func _root_pos_under_hips() -> Vector3:
	var hl := _local_targets[_hips_index].origin
	var offset := global_basis * Vector3(hl.x, 0.0, hl.z)
	var h := _bones[_hips_index].global_position
	return Vector3(h.x - offset.x, _rest_y, h.z - offset.z)

#var 
func activate_ragdoll(impulse: Vector3 = Vector3.ZERO) -> void:
	# A hit mid-recovery cancels the tween and goes back to ragdoll
	if _recover_tween and _recover_tween.is_valid():
		_recover_tween.kill()

	if _state == State.ACTIVE:
		animation_player.stop()
		physical_bone_simulator_3d.physical_bones_start_simulation()
		freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		freeze = true
		_desired_velocity = Vector3.ZERO

	_state = State.RAGDOLL

	if impulse != Vector3.ZERO:
		var v := impulse / mass
		for b in _bones:
			b.linear_velocity = v
			b.angular_velocity = Vector3(
				randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * spin_strength

	_timer.start(ragdoll_time)   # restarts if already running

func deactivate_ragdoll() -> void:
	if _state != State.RAGDOLL:
		return
	_state = State.RECOVERING
	global_position = _root_pos_under_hips()

	_starts.clear()
	_targets.clear()
	for i in _bones.size():
		_starts.append(_bones[i].global_transform)
		_targets.append(global_transform * _local_targets[i])

	_recover_tween = create_tween()
	_recover_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_recover_tween.tween_method(_move_bones, 0.0, 1.0, return_time)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_recover_tween.tween_callback(_bones_arrived)

func _bones_arrived() -> void:
	physical_bone_simulator_3d.physical_bones_stop_simulation()
	freeze = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	animation_player.play(ANIM_NAME)
	animation_player.seek(0.0, true)
	_state = State.ACTIVE
	
func _move_bones(w: float) -> void:
	for i in _bones.size():
		var b := _bones[i]
		var from := _starts[i]
		var to := _targets[i]
		var q := from.basis.get_rotation_quaternion().slerp(to.basis.get_rotation_quaternion(), w)
		var xf := Transform3D(Basis(q), from.origin.lerp(to.origin, w))
		PhysicsServer3D.body_set_state(b.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, xf)
		b.linear_velocity = Vector3.ZERO
		b.angular_velocity = Vector3.ZERO


func take_damage(damage: float, hit_dir: Vector3, strength: float, hit_point: Vector3) -> void:
	var impulse := global_transform.basis.z * launch_strength + Vector3.UP * launch_up
	activate_ragdoll(impulse)

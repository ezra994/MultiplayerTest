extends Node3D
class_name GrabbingManager

signal bring_out_item()
signal dropped

@export var inventory_data: InventoryData
@export var max_carry_speed := 15.0
@export var throw_force := 12.0

@onready var player: CollisionObject3D = owner  # adjust to your player node
@onready var camera: Camera3D = $"../../Head/Camera3D"  # adjust path
@onready var looking_raycast: ShapeCast3D = $"../../Head/LookingRaycast"
@onready var object_position: Marker3D = $"../../Head/SpringArm3D/ObjectPosition"
@onready var inventory_manager: EquipmentController = $"../InventoryManager"

var grabbed_object: RigidBody3D = null

func _ready() -> void:
	looking_raycast.add_exception(player)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact"):
		var target := _get_closest_target()
		if target:
			grab(target)
		elif grabbed_object:
			drop()

func _physics_process(delta: float) -> void:
	if grabbed_object == null:
		return
	if not is_instance_valid(grabbed_object):
		grabbed_object = null
		return
		
	var direction := object_position.global_position - grabbed_object.global_position
	grabbed_object.linear_velocity = (direction / delta).limit_length(max_carry_speed)
	grabbed_object.angular_velocity = Vector3.ZERO

func grab(object: RigidBody3D) -> void:
	# Items go straight into the inventory
	if object is Item and inventory_data.add_item(object.item_data):
		object.queue_free()
	#	inventory_
		return
	# Inventory full, or not an Item: use the hand (only if it's empty)
	if grabbed_object:
		drop()
		
	grabbed_object = object
	grabbed_object.add_collision_exception_with(player)

func drop() -> RigidBody3D:
	var obj := grabbed_object
	if obj == null:
		print("obj is null")
		return null
	obj.remove_collision_exception_with(player)
	obj.linear_velocity *= 0.3
	grabbed_object = null
	dropped.emit(obj)
	return obj

func throw() -> void:
	var obj := drop()
	if obj:
		var dir := -camera.global_transform.basis.z
		obj.apply_central_impulse(dir * throw_force * obj.mass)

func throwable_object(scene: PackedScene) -> void:
	var throwing_thing = scene.instantiate()
	get_tree().current_scene.add_child(throwing_thing)
	throwing_thing.global_position = object_position.global_position
	var dir := -camera.global_transform.basis.z
	throwing_thing.apply_central_impulse(dir * throw_force * throwing_thing.mass)
	bring_out_item.emit()
	

func _get_closest_target() -> Node3D:
	looking_raycast.force_shapecast_update()
	var closest: Node3D = null
	var closest_dist := INF
	for i in looking_raycast.get_collision_count():
		var c = looking_raycast.get_collider(i)
		if not (c is RigidBody3D) or c == grabbed_object:
			continue
		var d := camera.global_position.distance_squared_to(looking_raycast.get_collision_point(i))
		if d < closest_dist:
			closest_dist = d
			closest = c
	return closest

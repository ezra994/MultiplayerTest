extends Node3D
class_name GrabbingManager


var grabbed_object: RigidBody3D = null
@export var max_carry_speed := 15.0
@export var throw_force := 12.0

@onready var player: CollisionObject3D = owner  # adjust to your player node
@onready var camera: Camera3D = $"../../Head/Camera3D"  # adjust path
@onready var looking_raycast: ShapeCast3D = $"../../Head/LookingRaycast"
@onready var object_position: Marker3D = $"../../Head/SpringArm3D/ObjectPosition"

signal dropped(body: RigidBody3D)
signal pickup(item: Item)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact"):
		if grabbed_object:
			drop()
			return
		if looking_raycast.is_colliding():
			var collided = looking_raycast.get_collider(0)
			if collided is Item:
				pickup.emit(collided)
			if collided is RigidBody3D:
				grab(collided)
	elif event.is_action_pressed("Throw") and grabbed_object:
		throw()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(grabbed_object):
		grabbed_object = null
		return
		
	var direction = object_position.global_position - grabbed_object.global_position
	var vel = direction / delta
	grabbed_object.linear_velocity = vel.limit_length(max_carry_speed)
	grabbed_object.angular_velocity = Vector3.ZERO

func grab(object: RigidBody3D) -> void:
	grabbed_object = object
	grabbed_object.add_collision_exception_with(player)

func drop() -> void:
	grabbed_object.reparent(get_tree().current_scene)
	grabbed_object.remove_collision_exception_with(player)
	grabbed_object.linear_velocity *= 0.3
	dropped.emit(grabbed_object)
	grabbed_object = null

func throw() -> void:
	var obj = grabbed_object
	drop()
	var dir = -camera.global_transform.basis.z
	obj.apply_central_impulse(dir * throw_force * obj.mass)

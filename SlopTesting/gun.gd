extends Node3D
class_name Gun

const BULLET_CASING = preload("uid://6essift3g3jb")

@export var rayCast: RayCast3D
@export var animationPlayer: AnimationPlayer
@export var bullet_marker: Marker3D
@export var MuzzleFlashParticle: GPUParticles3D

func shoot() -> float:
	shoot_bullet()
	spawn_bullet_casing()
	MuzzleFlashParticle.emitting = true
	animationPlayer.play("Shoot")
	return .5
	
func spawn_bullet_casing() -> void:
	var bul = BULLET_CASING.instantiate()
	get_tree().current_scene.add_child(bul)
	bul.apply_impulse(Vector3.BACK* 10.0)
	bul.global_position = bullet_marker.global_position

func shoot_bullet() -> void:
	if not rayCast.is_colliding():
		print("W")
		return
	
	print("H")
	var collider := rayCast.get_collider()
	var point := rayCast.get_collision_point()
	var shot_dir := (rayCast.to_global(rayCast.target_position) - rayCast.global_position).normalized()
	if collider.is_in_group("Enemy"):
		print("?")
		collider.take_damage(1.0, shot_dir, 30.0, point) #1 shot for testing
	elif collider is PhysicalBone3D: #When shooting bone it moves
		print("WHAt")
		collider.apply_impulse(shot_dir * 500.0, point - collider.global_position)
	else:
		print(collider.name)
		decal(rayCast.get_collision_normal())
		
const BULLETHOLE_DECAL = preload("uid://tdphqmt661bg")
func decal(normal: Vector3) -> void:
	var decal = BULLETHOLE_DECAL.instantiate()
	get_tree().current_scene.add_child(decal)
	decal.global_position = rayCast.get_collision_point()

	# Build an orthonormal basis whose Y axis is the surface normal
	var ref = Vector3.BACK if abs(normal.dot(Vector3.BACK)) < 0.99 else Vector3.RIGHT
	var x = normal.cross(ref).normalized()
	var z = x.cross(normal)
	decal.global_basis = Basis(x, normal, z)

	# Optional: random spin so holes don't all look identical
	decal.rotate_object_local(Vector3.UP, randf() * TAU)
		


		

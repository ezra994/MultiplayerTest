extends Node3D

@onready var skeleton: Skeleton3D = $metarig/Skeleton3D
@onready var sim: PhysicalBoneSimulator3D = $metarig/Skeleton3D/PhysicalBoneSimulator3D

func start(src: Skeleton3D, hit_dir: Vector3, hit_point: Vector3, strength: float, inherited_velocity: Vector3) -> void:
	# 1. match the enemy's current pose (bone names must match)
	if src:
		for i in skeleton.get_bone_count():
			var j := src.find_bone(skeleton.get_bone_name(i))
			if j != -1:
				skeleton.set_bone_pose(i, src.get_bone_pose(j))

	sim.physical_bones_start_simulation()
	await get_tree().physics_frame

	var bones: Array[PhysicalBone3D] = []
	for c in sim.get_children():
		if c is PhysicalBone3D:
			bones.append(c)

	# 2. find the bone closest to where the bullet hit
	var closest: PhysicalBone3D = bones[0]
	for b in bones:
		if b.global_position.distance_squared_to(hit_point) < closest.global_position.distance_squared_to(hit_point):
			closest = b

	for b in bones:
		b.linear_velocity = inherited_velocity               # 3. keep momentum
		b.apply_central_impulse(hit_dir * strength * 0.15)   # small push everywhere

	# 4. big push at the hit point (also adds spin)
	closest.apply_impulse(hit_dir * strength, hit_point - closest.global_position)

extends Node3D

@onready var skeleton_3d: Skeleton3D = $metarig/Skeleton3D

func _process(delta: float) -> void:
	var idx := skeleton_3d.find_bone("spine.003")
	var pose := skeleton_3d.get_bone_pose_rotation(idx)
	skeleton_3d.set_bone_pose_rotation(idx, pose * Quaternion(Vector3.RIGHT, deg_to_rad(10)))

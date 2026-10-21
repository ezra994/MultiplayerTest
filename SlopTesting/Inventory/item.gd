extends RigidBody3D
class_name Item



@export var item_data: ItemData

func pickup() -> ItemData:
	return item_data
	

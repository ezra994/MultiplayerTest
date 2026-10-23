extends Area3D
class_name Buyable

func buy() -> void:
	print("?")
	if get_parent().has_method("bought"):
		get_parent().bought()

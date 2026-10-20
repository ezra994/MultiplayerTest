extends Node3D
signal boughted

func bought() -> void:
	print("WORKS")
	boughted.emit()
	queue_free()

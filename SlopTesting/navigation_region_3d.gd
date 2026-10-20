extends NavigationRegion3D


func _on_wall_boughted() -> void:
	set_navigation_layer_value(1, true)
	print("Region layers now: ", navigation_layers)
	print("Server says: ", NavigationServer3D.region_get_navigation_layers(get_rid()))

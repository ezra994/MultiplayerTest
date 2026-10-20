extends PanelContainer
class_name ItemContainer
var slot_data
func set_item(new_slot_data: SlotData) -> void:
	if new_slot_data and new_slot_data.item_data and new_slot_data.item_data.texture:
		$MarginContainer/TextureRect.texture = new_slot_data.item_data.texture
	slot_data = new_slot_data

func highlight() -> void:
	offset_transform_scale = Vector2(1.25, 1.25)

func unhighlight() -> void:
	offset_transform_scale = Vector2(1.0, 1.0)

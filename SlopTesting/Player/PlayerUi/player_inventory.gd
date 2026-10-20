extends HBoxContainer

const ITEM_CONTAINER = preload("uid://1ndtyf7j3ekg")
@export var inventory_data: InventoryData

func _ready() -> void:
	inventory_data.changed.connect(_rebuild)
	inventory_data.selected_changed.connect(_highlight)
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	for data in inventory_data.slot_datas:
		var c: ItemContainer = ITEM_CONTAINER.instantiate()
		c.set_item(data)
		add_child(c)
	_highlight(inventory_data.selected_index)

func _highlight(index: int) -> void:
	for i in get_child_count():
		var c = get_child(i)
		if i == index: c.highlight()
		else: c.unhighlight()

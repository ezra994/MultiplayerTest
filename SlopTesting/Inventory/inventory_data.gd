extends Resource
class_name InventoryData

signal selected_changed(index: int)
@export var slot_datas: Array[SlotData]
@export var hand_slot: SlotData
var selected_index := 0

func select(index: int) -> void:
	if index < 0 or index >= slot_datas.size() or index == selected_index:
		return
	selected_index = index
	selected_changed.emit(index)

func cycle(step: int) -> void:
	select(posmod(selected_index + step, slot_datas.size()))

func get_selected() -> SlotData:
	return slot_datas[selected_index]

func add_item(item_data: ItemData) -> bool:
	for i in slot_datas.size():
		var s := slot_datas[i]
		if s == null or s.item_data == null:
			var new_slot := SlotData.new()
			new_slot.item_data = item_data.duplicate(true)
			slot_datas[i] = new_slot
			emit_changed()
			if i == selected_index:
				selected_changed.emit(i)
			return true
	return false

func remove_from_slot(held_slot) -> void:
	print("HELLO")
	slot_datas[held_slot] = null
	emit_changed()

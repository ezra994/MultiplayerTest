class_name EquipmentController
extends Node

@export var inventory_data: InventoryData
@onready var grabbing_manager: Node3D = $"../GrabbingManager"
@export var item_holder: Node3D
var can_switch := true

var held_item: Node
var held_slot := -1

func _ready() -> void:
	await get_tree().physics_frame
	inventory_data.selected_changed.connect(func(i): _equip_selected())
	grabbing_manager.dropped.connect(on_dropped)
	grabbing_manager.pickup.connect(add_item)
	#_equip_selected()
	
func _unhandled_input(event: InputEvent) -> void:
	if not can_switch: return
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:  # your range() excluded KEY_9
			inventory_data.select(event.keycode - KEY_1)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: inventory_data.cycle(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: inventory_data.cycle(-1)
		
	if event.is_action_pressed("LeftClick") and held_item and held_item.has_method("shoot"):
		held_item.shoot()  
	
	#if event.is_action_pressed("Throw"):
		#if inventory_data.get_selected() != null and inventory_data.get_selected().item_data != null:
			#if inventory_data.get_selected().item_data.hold_mode == ItemData.HoldMode.HAND:
				#grabbing_manager.test()
		
func _equip_selected() -> void:
	_clear_held()
	var slot := inventory_data.get_selected()
	if slot == null or slot.item_data == null: return

	var item := slot.item_data
	match item.hold_mode:
		ItemData.HoldMode.HAND:
			held_item = item.scene.instantiate()
			item_holder.add_child(held_item)
		ItemData.HoldMode.GRAB:
			var body := item.scene.instantiate() as RigidBody3D
			get_tree().current_scene.add_child(body)
			body.global_transform = item_holder.global_transform
			grabbing_manager.grab(body)
			held_item = body
	held_slot = inventory_data.selected_index

func _clear_held() -> void:
	if held_item == null:
		return

	if held_item == grabbing_manager.grabbed_object:
		grabbing_manager.grabbed_object = null

	held_item.queue_free()
	held_item = null
	
func on_dropped(body: RigidBody3D) -> void:
	if body == held_item:
		held_item = null
		inventory_data.remove_from_slot(held_slot)

func add_item(item: Item) -> void:
	if item:
		inventory_data.add_item(item.pickup())
		held_item = item

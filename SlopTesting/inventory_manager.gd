class_name EquipmentController
extends Node

var current_item_scene: Node
@export var inventory_data: InventoryData
@onready var grabbing_manager: Node3D = $"../GrabbingManager"
@export var item_holder: Node3D
var can_switch := true
#
#var held_item: Node
#var held_slot := -1
#
func _ready() -> void:
	grabbing_manager.dropped.connect(on_drop)
	grabbing_manager.bring_out_item.connect(remove_slot)
	await get_tree().physics_frame
	inventory_data.selected_changed.connect(func(i): _equip_selected())
	#grabbing_manager.dropped.connect(on_dropped)
	#grabbing_manager.pickup.connect(add_item)
	##_equip_selected()
	#
func _unhandled_input(event: InputEvent) -> void:
	if not can_switch: return
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:  # your range() excluded KEY_9
			inventory_data.select(event.keycode - KEY_1)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: inventory_data.cycle(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: inventory_data.cycle(-1)
		#
	if event.is_action_pressed("LeftClick") and current_item_scene and current_item_scene.has_method("shoot"):
		current_item_scene.shoot()  
	#
	if event.is_action_pressed("Throw"):
		throw()
	
	if event.is_action_pressed("Interact"):
		interact()
func _equip_selected() -> void:
	_clear_held()
	var slot := inventory_data.get_selected()
	if slot == null or slot.item_data == null: return
#
	var item := slot.item_data
	match item.hold_mode:
		ItemData.HoldMode.HAND:
			current_item_scene = item.scene.instantiate()
			item_holder.add_child(current_item_scene)
		ItemData.HoldMode.GRAB:
			var body := item.scene.instantiate() as RigidBody3D
			if body is Item:
				body.item_data = item
			get_tree().current_scene.add_child(body)
			body.global_transform = item_holder.global_transform
			grabbing_manager.grab(body)   # not grab(), see below
			current_item_scene = body

func throw() -> void:
	# Holding a regular grabbed object (not the equipped item): throw only that
	var g = grabbing_manager.grabbed_object
	if g and g != current_item_scene:
		grabbing_manager.throw()
		return

	# Otherwise throw the equipped item
	var slot := inventory_data.get_selected()
	if slot == null or slot.item_data == null: return
	
	if slot.item_data.hold_mode == ItemData.HoldMode.HAND:
		if slot.item_data.throwable_scene == null: return
		else: 
			await get_tree().physics_frame
			grabbing_manager.throwable_object(slot.item_data.throwable_scene)
	elif slot.item_data.hold_mode == ItemData.HoldMode.GRAB:
		current_item_scene = null
		grabbing_manager.throw()
		remove_slot()

func interact() -> void:
	var g = grabbing_manager.grabbed_object
	if g and g != current_item_scene:
		grabbing_manager.drop()
		return

	# Otherwise throw the equipped item
	var slot := inventory_data.get_selected()
	if slot == null or slot.item_data == null or slot.item_data.hold_mode == ItemData.HoldMode.HAND: grabbing_manager.test()
	
	elif slot.item_data.hold_mode == ItemData.HoldMode.GRAB:
		current_item_scene = null
		grabbing_manager.drop()
		remove_slot()

func _clear_held() -> void:
	if is_instance_valid(current_item_scene):
		current_item_scene.queue_free()
	current_item_scene = null

func remove_slot() -> void:
	inventory_data.slot_datas[inventory_data.selected_index] = null
	_clear_held()  # remove the equipped model/body, since selected_changed won't fire
	inventory_data.emit_changed()
	
func on_drop(body: RigidBody3D) -> void:
	if body != current_item_scene:
		return
	current_item_scene = null  # detach so nothing frees the dropped body
	inventory_data.slot_datas[inventory_data.selected_index] = null
	inventory_data.emit_changed()

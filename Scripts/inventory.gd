extends Node2D

const SlotClass = preload("res://Scripts/slot.gd")

@onready var inventory_slots = $GridContainer
@onready var equip_slots = $EquipSlots.get_children()

func _ready():
	var slots = inventory_slots.get_children()
	for i in range(slots.size()):
		slots[i].gui_input.connect(slot_gui_input.bind(slots[i]))
		slots[i].slot_index = i
		slots[i].slotType = SlotClass.SlotType.INVENTORY

	for i in range(equip_slots.size()):
		equip_slots[i].gui_input.connect(slot_gui_input.bind(equip_slots[i]))
		equip_slots[i].slot_index = i

	equip_slots[0].slotType = SlotClass.SlotType.SHIRT
	equip_slots[1].slotType = SlotClass.SlotType.PANTS
	equip_slots[2].slotType = SlotClass.SlotType.SHOES

	initialize_inventory()
	initialize_equips()

func initialize_inventory():
	var slots = inventory_slots.get_children()
	for i in range(slots.size()):
		if PlayerInventory.inventory.has(i):
			slots[i].initialize_item(PlayerInventory.inventory[i][0], PlayerInventory.inventory[i][1])

func initialize_equips():
	for i in range(equip_slots.size()):
		if PlayerInventory.equips.has(i):
			equip_slots[i].initialize_item(PlayerInventory.equips[i][0], PlayerInventory.equips[i][1])

func slot_gui_input(event: InputEvent, slot: SlotClass):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var ui = find_parent("UserInterface")
		if ui.holding_item != null:
			if !slot.item:
				left_click_empty_slot(slot)
			else:
				if ui.holding_item.item_name != slot.item.item_name:
					left_click_different_item(event, slot)
				else:
					left_click_same_item(slot)
		elif slot.item:
			left_click_not_holding(slot)

func _input(event):
	var ui = find_parent("UserInterface")
	if ui.holding_item:
		ui.holding_item.global_position = get_global_mouse_position()

func able_to_put_into_slot(slot: SlotClass):
	var holding_item = find_parent("UserInterface").holding_item
	if holding_item == null:
		return true

	var holding_item_category = JsonData.item_data[holding_item.item_name]["ItemCategory"]

	match slot.slotType:
		SlotClass.SlotType.SHIRT:
			return holding_item_category == "Shirt"
		SlotClass.SlotType.PANTS:
			return holding_item_category == "Pants"
		SlotClass.SlotType.SHOES:
			return holding_item_category == "Shoes"
		_:
			return true

func left_click_empty_slot(slot: SlotClass):
	if able_to_put_into_slot(slot):
		var ui = find_parent("UserInterface")
		PlayerInventory.add_item_to_empty_slot(ui.holding_item, slot)
		slot.putIntoSlot(ui.holding_item)
		ui.holding_item = null

func left_click_different_item(event: InputEvent, slot: SlotClass):
	if able_to_put_into_slot(slot):
		var ui = find_parent("UserInterface")
		PlayerInventory.remove_item(slot)
		PlayerInventory.add_item_to_empty_slot(ui.holding_item, slot)
		var temp_item = slot.item
		slot.pickFromSlot()
		temp_item.global_position = event.global_position
		slot.putIntoSlot(ui.holding_item)
		ui.holding_item = temp_item

func left_click_same_item(slot: SlotClass):
	if able_to_put_into_slot(slot):
		var ui = find_parent("UserInterface")
		var stack_size = int(JsonData.item_data[slot.item.item_name]["StackSize"])
		var able_to_add = stack_size - slot.item.item_quantity
		if able_to_add >= ui.holding_item.item_quantity:
			PlayerInventory.add_item_quantity(slot, ui.holding_item.item_quantity)
			slot.item.add_item_quantity(ui.holding_item.item_quantity)
			ui.holding_item.queue_free()
			ui.holding_item = null
		else:
			PlayerInventory.add_item_quantity(slot, able_to_add)
			slot.item.add_item_quantity(able_to_add)
			ui.holding_item.decrease_item_quantity(able_to_add)

func left_click_not_holding(slot: SlotClass):
	var ui = find_parent("UserInterface")
	PlayerInventory.remove_item(slot)
	ui.holding_item = slot.item
	slot.pickFromSlot()
	ui.holding_item.global_position = get_global_mouse_position()

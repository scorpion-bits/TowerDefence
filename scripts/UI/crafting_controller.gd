extends RefCounted

# Controla a aba de Crafting (inventário de materiais, slots de combinação, receitas).
# Extraído de ui.gd (Fase 6.5 da refatoração incremental). É um RefCounted comum, não
# um Node — por isso não precisa de nenhuma mudança em ui.tscn.

var inventory_grid: GridContainer
var slot0: Button
var slot1: Button
var slot2: Button
var result_slot: Button
var recipes_vbox: VBoxContainer

var current_crafting_items: Array[String] = []

func _init(p_inventory_grid: GridContainer, p_slot0: Button, p_slot1: Button, p_slot2: Button,
		p_result_slot: Button, p_recipes_vbox: VBoxContainer, craft_button: Button, clear_button: Button) -> void:
	inventory_grid = p_inventory_grid
	slot0 = p_slot0
	slot1 = p_slot1
	slot2 = p_slot2
	result_slot = p_result_slot
	recipes_vbox = p_recipes_vbox

	if craft_button: craft_button.pressed.connect(_on_craft_pressed)
	if clear_button: clear_button.pressed.connect(_on_clear_pressed)

	GameManager.inventory_changed.connect(_update_inventory_ui)

	_update_inventory_ui()
	_update_crafting_slots()
	_load_recipes()

func _update_inventory_ui() -> void:
	if not inventory_grid: return
	for c in inventory_grid.get_children():
		c.queue_free()

	for item in GameManager.inventory:
		var amount = GameManager.inventory[item]
		if amount > 0:
			var btn = Button.new()
			btn.text = "%s (%d)" % [item.substr(0, 3), amount]
			btn.tooltip_text = item
			btn.custom_minimum_size = Vector2(40, 40)
			btn.pressed.connect(func(): _on_inventory_item_clicked(item))
			inventory_grid.add_child(btn)

func _on_inventory_item_clicked(item: String) -> void:
	if current_crafting_items.size() < 3:
		current_crafting_items.append(item)
		_update_crafting_slots()

func _on_clear_pressed() -> void:
	current_crafting_items.clear()
	_update_crafting_slots()

func _update_crafting_slots() -> void:
	var slots = [slot0, slot1, slot2]
	for i in range(3):
		if i < current_crafting_items.size():
			slots[i].text = current_crafting_items[i].substr(0, 3)
		else:
			slots[i].text = ""

	var result = _check_recipe()
	if result != "":
		result_slot.text = result
	else:
		result_slot.text = ""

func _check_recipe() -> String:
	var current_sorted = current_crafting_items.duplicate()
	current_sorted.sort()

	for tower_name in GameManager.recipes:
		var req = GameManager.recipes[tower_name].duplicate()
		req.sort()
		if current_sorted == req:
			return tower_name
	return ""

func _on_craft_pressed() -> void:
	var result = _check_recipe()
	if result != "":
		GameManager.tower_inventory[result] = GameManager.tower_inventory.get(result, 0) + 1
		for item in current_crafting_items:
			GameManager.inventory[item] -= 1

		var needed = {}
		for item in current_crafting_items:
			needed[item] = needed.get(item, 0) + 1

		var can_keep = true
		for item in needed:
			if GameManager.inventory.get(item, 0) < needed[item]:
				can_keep = false
				break

		if not can_keep:
			current_crafting_items.clear()

		_update_crafting_slots()
		_update_inventory_ui()
		GameManager.tower_inventory_changed.emit()

func _load_recipes() -> void:
	if not recipes_vbox: return

	for child in recipes_vbox.get_children():
		child.queue_free()

	for tower_name in GameManager.recipes:
		var req = GameManager.recipes[tower_name]
		var label = Label.new()
		label.text = tower_name + ":\n  " + " + ".join(req)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		recipes_vbox.add_child(label)

		var sep = HSeparator.new()
		recipes_vbox.add_child(sep)

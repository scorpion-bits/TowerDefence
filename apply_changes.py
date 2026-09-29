import os

with open('scripts/UI/ui.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _create_tower_button
old_create = '''func _create_tower_button(data: TowerData) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(85, 85)
	btn.text = "$%d\\n%s" % [data.cost, data.tower_name]

	if GameManager.unlocked_towers.has(data.tower_name):
		btn.tooltip_text = "Dano: %d\\nVelocidade: %.1f\\nAlcance: %d" % [data.attack_damage, 1.0/data.attack_cooldown, data.attack_range]
		btn.disabled = false
	else:
		var req = GameManager.recipes.get(data.tower_name, [])
		btn.tooltip_text = "BLOQUEADA\\nReceita: " + ", ".join(req)
		btn.disabled = true

	btn.button_down.connect(func(): GameManager.drag_started.emit(data))
	grid_container.add_child(btn)'''

new_create = '''func _create_tower_button(data: TowerData) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(85, 85)
	
	var amount = GameManager.tower_inventory.get(data.tower_name, 0)
	var short_name = data.tower_name.split(" ")[0]
	btn.text = "%s\\n(%d)" % [short_name, amount]

	if amount > 0:
		btn.tooltip_text = "Dano: %d\\nVelocidade: %.1f\\nAlcance: %d" % [data.attack_damage, 1.0/data.attack_cooldown, data.attack_range]
		btn.disabled = false
	else:
		var req = GameManager.recipes.get(data.tower_name, [])
		btn.tooltip_text = "RECEITA:\\n" + ", ".join(req)
		btn.disabled = true

	btn.button_down.connect(func(): GameManager.drag_started.emit(data))
	grid_container.add_child(btn)'''

content = content.replace(old_create, new_create)

# Replace craft logic
old_craft = '''func _on_craft_pressed() -> void:
	var result = _check_recipe()
	if result != "":
		# Unlock tower
		if not GameManager.unlocked_towers.has(result):
			GameManager.unlocked_towers.append(result)
		
		# Consume items
		for item in current_crafting_items:
			GameManager.inventory[item] -= 1
			
		current_crafting_items.clear()
		_update_crafting_slots()
		_update_inventory_ui()
		
		# Refresh the build shop
		_load_towers()'''

new_craft = '''func _on_craft_pressed() -> void:
	var result = _check_recipe()
	if result != "":
		GameManager.tower_inventory[result] = GameManager.tower_inventory.get(result, 0) + 1
		for item in current_crafting_items:
			GameManager.inventory[item] -= 1
		current_crafting_items.clear()
		_update_crafting_slots()
		_update_inventory_ui()
		GameManager.tower_inventory_changed.emit()'''

content = content.replace(old_craft, new_craft)

# Add signal connection in _ready if not present
if 'GameManager.tower_inventory_changed' not in content:
    content = content.replace('_load_towers()', 'GameManager.tower_inventory_changed.connect(_load_towers)\\n\\t_load_towers()')

with open('scripts/UI/ui.gd', 'w', encoding='utf-8') as f:
    f.write(content)

# Now update level.gd
with open('scripts/Level/level.gd', 'r', encoding='utf-8') as f:
    level = f.read()

old_build = '''func _try_build_tower() -> void:
	if current_ghost.is_valid_location:
		if GameManager.spend_xp(dragging_data.cost):
			var new_tower = tower_scene.instantiate()
			new_tower.setup(dragging_data)
			new_tower.global_position = current_ghost.global_position
			.add_child(new_tower)
		else:
			print("Sem xp!")
			
	_cancel_drag()'''

new_build = '''func _try_build_tower() -> void:
	if current_ghost.is_valid_location:
		var amount = GameManager.tower_inventory.get(dragging_data.tower_name, 0)
		if amount > 0:
			GameManager.tower_inventory[dragging_data.tower_name] = amount - 1
			GameManager.tower_inventory_changed.emit()
			var new_tower = tower_scene.instantiate()
			new_tower.setup(dragging_data)
			new_tower.global_position = current_ghost.global_position
			.add_child(new_tower)
			
	_cancel_drag()'''

# Try replacing generic logic if old_build doesn't perfectly match
if 'GameManager.spend_xp' in level:
    # We will just replace the function completely using a simpler split or regex
    import re
    level = re.sub(r'func _try_build_tower\(\) -> void:.*?(?=\n\n|\Z)', new_build, level, flags=re.DOTALL)
    
with open('scripts/Level/level.gd', 'w', encoding='utf-8') as f:
    f.write(level)


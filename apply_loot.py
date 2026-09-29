import os

with open('scripts/Autoload/game_manager.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Add signal inventory_changed
if 'signal inventory_changed' not in content:
    content = content.replace('signal tower_inventory_changed', 'signal tower_inventory_changed\\nsignal inventory_changed')

# Add roll_loot function
loot_func = '''
func roll_loot() -> void:
	# 35% chance to drop a random material
	if randf() < 0.35:
		var items = inventory.keys()
		var item = items[randi() % items.size()]
		inventory[item] += 1
		inventory_changed.emit()
'''
if 'func roll_loot' not in content:
    content += loot_func

with open('scripts/Autoload/game_manager.gd', 'w', encoding='utf-8') as f:
    f.write(content)

with open('scripts/Enemy/enemy.gd', 'r', encoding='utf-8') as f:
    enemy = f.read()

if 'GameManager.roll_loot()' not in enemy:
    enemy = enemy.replace('GameManager.add_xp(data.reward)', 'GameManager.add_xp(data.reward)\\n\\tGameManager.roll_loot()')

with open('scripts/Enemy/enemy.gd', 'w', encoding='utf-8') as f:
    f.write(enemy)

with open('scripts/UI/ui.gd', 'r', encoding='utf-8') as f:
    ui = f.read()

if 'GameManager.inventory_changed.connect(_update_inventory_ui)' not in ui:
    ui = ui.replace('GameManager.tower_inventory_changed.connect(_load_towers)', 'GameManager.tower_inventory_changed.connect(_load_towers)\\n\\tGameManager.inventory_changed.connect(_update_inventory_ui)')

with open('scripts/UI/ui.gd', 'w', encoding='utf-8') as f:
    f.write(ui)

import os

def fix_file(path, replacements, fix_accents=False):
    with open(path, 'r', encoding='windows-1252' if fix_accents else 'utf-8', errors='ignore') as f:
        content = f.read()
    
    for old, new in replacements:
        content = content.replace(old, new)
        
    if fix_accents:
        content = content.replace('Bǭsico', 'Básico')
        content = content.replace('Glbulos', 'Glóbulos')
        content = content.replace('Lentidǜo', 'Lentidão')
        content = content.replace('Canhǜo', 'Canhão')
        content = content.replace('Peonhenta', 'Peçonhenta')
        content = content.replace('Vitria', 'Vitória')
        content = content.replace('RǸgia', 'Régia')
        content = content.replace('Mandrǭgora', 'Mandrágora')
        # Handle all possible corruptions by just re-pasting the dicts since it's easier
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# We can just rewrite game_manager.gd entirely to be 100% safe
gm_content = '''extends Node

signal xp_changed(new_amount: int)
signal lives_changed(new_amount: int)
signal game_over
signal victory
signal drag_started(tower_data: TowerData)
signal start_wave_requested
signal auto_start_toggled(enabled: bool)
signal wave_updated(wave_number: int)
signal tower_selected(tower: Node2D)
signal tower_deselected
signal tower_inventory_changed
signal inventory_changed

var xp: int = 150

var tower_inventory: Dictionary = {"Esqueleto (Básico)": 1}

var inventory: Dictionary = {
	"Pedra": 5, "Vagalume": 5, "Mandrágora": 5, "Vitória Régia": 5,
	"Gelo": 5, "Palha": 5, "Osso": 5, "Asas de Borboleta": 5,
	"Magma": 5, "Graveto": 5, "Glóbulos Oculares": 5, "Espinhos de Rosa": 5
}

var recipes = {
	"Espantalho (Buff)": ["Graveto", "Palha"],
	"Esqueleto (Básico)": ["Osso", "Osso"],
	"Golem de Gelo (Lentidão)": ["Pedra", "Gelo"],
	"Golem de Pedra (Canhão)": ["Pedra", "Pedra"],
	"Sapo (Sniper)": ["Vitória Régia", "Vagalume"],
	"Olho Flutuante (Laser)": ["Glóbulos Oculares", "Asas de Borboleta"],
	"Golem de Fogo (Chamas)": ["Pedra", "Magma"],
	"Planta Peçonhenta": ["Graveto", "Espinhos de Rosa", "Vitória Régia"]
}

var lives: int = 20

func add_xp(amount: int) -> void:
	xp += amount
	xp_changed.emit(xp)

func spend_xp(amount: int) -> bool:
	if xp >= amount:
		xp -= amount
		xp_changed.emit(xp)
		return true
	return false

func take_damage(amount: int) -> void:
	lives -= amount
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()
		print("game over")

func roll_loot() -> void:
	# 35% chance to drop a random material
	if randf() < 0.35:
		var items = inventory.keys()
		var item = items[randi() % items.size()]
		inventory[item] += 1
		inventory_changed.emit()
'''

with open('scripts/Autoload/game_manager.gd', 'w', encoding='utf-8') as f:
    f.write(gm_content)


ui_replacements = [
    (r'\n\tGameManager.inventory_changed', '\n\tGameManager.inventory_changed'),
]
with open('scripts/UI/ui.gd', 'r', encoding='utf-8') as f:
    ui = f.read()

ui = ui.replace(r'\n\t', '\n\t')

with open('scripts/UI/ui.gd', 'w', encoding='utf-8') as f:
    f.write(ui)


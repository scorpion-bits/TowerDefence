import os

content = '''extends Node

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
'''

with open('scripts/Autoload/game_manager.gd', 'wb') as f:
    f.write(content.encode('utf-8'))

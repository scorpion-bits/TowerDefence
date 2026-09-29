extends Node

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
signal item_dropped(item_name: String)

var xp: int = 150

var tower_inventory: Dictionary = {"Esqueleto (Básico)": 1}

var inventory: Dictionary = {
	"Pedra": 0, "Vagalume": 0, "Mandrágora": 0, "Vitória Régia": 0,
	"Gelo": 0, "Palha": 0, "Osso": 0, "Asas de Borboleta": 0,
	"Magma": 0, "Graveto": 0, "Glóbulos Oculares": 0, "Espinhos de Rosa": 0
}

func _ready() -> void:
	var item_keys = inventory.keys()
	item_keys.shuffle()
	for i in range(4):
		inventory[item_keys[i]] = 2

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
	# 5% chance to drop a random material
	if randf() < 0.05:
		var items = inventory.keys()
		var item = items[randi() % items.size()]
		inventory[item] += 1
		inventory_changed.emit()
		item_dropped.emit(item)

extends Node

# Sistema de inventário, crafting e loja, extraído do GameManager (Fase 6.4 da
# refatoração incremental). GameManager mantém propriedades e funções de
# encaminhamento para preservar compatibilidade total com o código existente
# (ui.gd, level.gd, enemy.gd, skill_manager.gd).

signal inventory_changed
signal item_dropped(item_name: String)
signal shop_updated

var tower_inventory: Dictionary = {"Esqueleto (Básico)": 1}

var inventory: Dictionary = {
	"Pedra": 0, "Vagalume": 0, "Mandrágora": 0, "Vitória Régia": 0,
	"Gelo": 0, "Palha": 0, "Osso": 0, "Asas de Borboleta": 0,
	"Magma": 0, "Graveto": 0, "Glóbulos Oculares": 0, "Espinhos de Rosa": 0
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

var current_shop_item: String = ""

func _ready() -> void:
	var item_keys = inventory.keys()
	item_keys.shuffle()
	for i in range(4):
		inventory[item_keys[i]] = 2
	refresh_shop()

func roll_loot() -> void:
	if randf() < 0.05:
		var items = inventory.keys()
		var item = items[randi() % items.size()]
		inventory[item] += 1
		inventory_changed.emit()
		item_dropped.emit(item)

func refresh_shop() -> void:
	var items = inventory.keys()
	if items.size() > 0:
		current_shop_item = items[randi() % items.size()]
		shop_updated.emit()

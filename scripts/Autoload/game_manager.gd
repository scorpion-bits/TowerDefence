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

signal skill_points_changed(new_amount: int)
signal skill_unlocked(skill_id: String)

var xp: int = 150
var lives: int = 20

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

# --- SISTEMA DE ARVORE DE HABILIDADES ---
var skill_points: int = 0
var unlocked_skills: Dictionary = {"base_start": true} 

var skill_tree_data: Dictionary = {
	"base_start": {
		"tower": "Global",
		"stat": "none",
		"value": 0.0,
		"requires": []
	},
	"skel_dmg_1": {
		"tower": "Esqueleto (Básico)",
		"stat": "damage",
		"value": 1.0,
		"requires": ["base_start"]
	},
	"skel_spd_1": {
		"tower": "Esqueleto (Básico)",
		"stat": "fire_rate", 
		"value": 0.1,
		"requires": ["skel_dmg_1"]
	},
	"fire_dmg_1": {
		"tower": "Golem de Fogo (Chamas)",
		"stat": "damage",
		"value": 2.0,
		"requires": ["base_start"]
	}
}

func _ready() -> void:
	var item_keys = inventory.keys()
	item_keys.shuffle()
	for i in range(4):
		inventory[item_keys[i]] = 2

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
	if randf() < 0.05:
		var items = inventory.keys()
		var item = items[randi() % items.size()]
		inventory[item] += 1
		inventory_changed.emit()
		item_dropped.emit(item)

# --- FUNCOES DA ARVORE DE HABILIDADES ---
func add_skill_point() -> void:
	skill_points += 1
	skill_points_changed.emit(skill_points)

func get_next_skill_cost() -> int:
	var bought_count = unlocked_skills.size()
	if unlocked_skills.has("base_start"):
		bought_count -= 1
	return bought_count + 1

func buy_skill(skill_id: String) -> bool:
	if unlocked_skills.has(skill_id): return false
	
	var cost = get_next_skill_cost()
	if skill_points >= cost:
		skill_points -= cost
		unlocked_skills[skill_id] = true
		skill_points_changed.emit(skill_points)
		skill_unlocked.emit(skill_id)
		return true
	return false

func get_tower_bonus(tower_name: String, stat: String) -> float:
	var total_bonus: float = 0.0
	for skill_id in unlocked_skills:
		if skill_tree_data.has(skill_id):
			var data = skill_tree_data[skill_id]
			if (data.tower == tower_name or data.tower == "Global") and data.stat == stat:
				total_bonus += float(data.value)
	return total_bonus

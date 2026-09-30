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
	"esqueleto_base": { "tower": "Esqueleto (Básico)", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },
	"esqueleto_range_1": { "tower": "Esqueleto (Básico)", "stat": "range", "value": 20.0, "requires": ["esqueleto_base"] },
	"esqueleto_damage_1": { "tower": "Esqueleto (Básico)", "stat": "damage", "value": 1.0, "requires": ["esqueleto_base"] },
	"esqueleto_spd_1": { "tower": "Esqueleto (Básico)", "stat": "fire_rate", "value": 0.15, "requires": ["esqueleto_base"] },
	
	"esqueleto_mirada_alta": { "tower": "Esqueleto (Básico)", "stat": "range", "value": 30.0, "requires": ["esqueleto_range_1"] },
	"esqueleto_estilhaco": { "tower": "Esqueleto (Básico)", "stat": "special", "value": 0.0, "requires": ["esqueleto_damage_1"] },
	"esqueleto_arco_duplo": { "tower": "Esqueleto (Básico)", "stat": "special", "value": 0.0, "requires": ["esqueleto_spd_1"] },
	"esqueleto_chuva": { "tower": "Esqueleto (Básico)", "stat": "special", "value": 0.0, "requires": ["esqueleto_arco_duplo"], "exclusive_group": "esqueleto_tier3" },
	"esqueleto_maldicao": { "tower": "Esqueleto (Básico)", "stat": "special", "value": 0.0, "requires": ["esqueleto_estilhaco"], "exclusive_group": "esqueleto_tier3" },
	"esqueleto_perfurante": { "tower": "Esqueleto (Básico)", "stat": "special", "value": 0.0, "requires": ["esqueleto_mirada_alta"], "exclusive_group": "esqueleto_tier3" },

	"fogo_base": { "tower": "Golem de Fogo (Chamas)", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },
	"sapo_base": { "tower": "Sapo (Sniper)", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },
	
	"olho_base": { "tower": "Olho Flutuante (Laser)", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },
	"olho_spd_1": { "tower": "Olho Flutuante (Laser)", "stat": "special", "value": 0.0, "requires": ["olho_base"] },
	"olho_calor_1": { "tower": "Olho Flutuante (Laser)", "stat": "special", "value": 0.0, "requires": ["olho_spd_1"] },
	"olho_fusao": { "tower": "Olho Flutuante (Laser)", "stat": "special", "value": 0.0, "requires": ["olho_calor_1"], "exclusive_group": "olho_tier3" },

	"olho_dano_1": { "tower": "Olho Flutuante (Laser)", "stat": "special", "value": 0.0, "requires": ["olho_base"] },
	"olho_bifurcado": { "tower": "Olho Flutuante (Laser)", "stat": "special", "value": 0.0, "requires": ["olho_dano_1"] },
	"olho_cadeia": { "tower": "Olho Flutuante (Laser)", "stat": "special", "value": 0.0, "requires": ["olho_bifurcado"], "exclusive_group": "olho_tier3" },

	"olho_range_1": { "tower": "Olho Flutuante (Laser)", "stat": "range", "value": 20.0, "requires": ["olho_base"] },
	"olho_instant": { "tower": "Olho Flutuante (Laser)", "stat": "special", "value": 0.0, "requires": ["olho_range_1"] },
	"olho_satelite": { "tower": "Olho Flutuante (Laser)", "stat": "range", "value": 40.0, "requires": ["olho_instant"], "exclusive_group": "olho_tier3" },

	"pedra_base": { "tower": "Golem de Pedra (Canhão)", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },
	
	"espantalho_base": { "tower": "Espantalho (Buff)", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },
	"espantalho_dano_1": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "requires": ["espantalho_base"] },
	"espantalho_spd_1": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "requires": ["espantalho_dano_1"] },
	"espantalho_frenesi": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "requires": ["espantalho_spd_1"], "exclusive_group": "espantalho_tier3" },

	"espantalho_slow_1": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "requires": ["espantalho_base"] },
	"espantalho_xp_1": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "requires": ["espantalho_slow_1"] },
	"espantalho_panico": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "requires": ["espantalho_xp_1"], "exclusive_group": "espantalho_tier3" },

	"espantalho_range_1": { "tower": "Espantalho (Buff)", "stat": "range_pct", "value": 0.20, "requires": ["espantalho_base"] },
	"espantalho_range_buff": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "requires": ["espantalho_range_1"] },
	"espantalho_sinergia": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "requires": ["espantalho_range_buff"], "exclusive_group": "espantalho_tier3" },

	"gelo_base": { "tower": "Golem de Gelo (Lentidão)", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },
	"planta_base": { "tower": "Planta Peçonhenta", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },
	
	"planta_dano_1": { "tower": "Planta Peçonhenta", "stat": "special", "value": 0.0, "requires": ["planta_base"] },
	"planta_stack_1": { "tower": "Planta Peçonhenta", "stat": "special", "value": 0.0, "requires": ["planta_dano_1"] },
	"planta_necrose": { "tower": "Planta Peçonhenta", "stat": "special", "value": 0.0, "requires": ["planta_stack_1"], "exclusive_group": "planta_tier3" },

	"planta_spd_1": { "tower": "Planta Peçonhenta", "stat": "fire_rate", "value": 0.20, "requires": ["planta_base"] },
	"planta_esporos": { "tower": "Planta Peçonhenta", "stat": "special", "value": 0.0, "requires": ["planta_spd_1"] },
	"planta_epidemia": { "tower": "Planta Peçonhenta", "stat": "special", "value": 0.0, "requires": ["planta_esporos"], "exclusive_group": "planta_tier3" },

	"planta_range_1": { "tower": "Planta Peçonhenta", "stat": "range_pct", "value": 0.20, "requires": ["planta_base"] },
	"planta_neuro": { "tower": "Planta Peçonhenta", "stat": "special", "value": 0.0, "requires": ["planta_range_1"] },
	"planta_acido": { "tower": "Planta Peçonhenta", "stat": "special", "value": 0.0, "requires": ["planta_neuro"], "exclusive_group": "planta_tier3" },
	
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
	
	if skill_tree_data.has(skill_id):
		var data = skill_tree_data[skill_id]
		if data.has("exclusive_group"):
			for other_id in unlocked_skills:
				var other_data = skill_tree_data.get(other_id)
				if other_data and other_data.has("exclusive_group") and other_data.exclusive_group == data.exclusive_group:
					return false
	
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

func has_skill(skill_id: String) -> bool:
	return unlocked_skills.has(skill_id)

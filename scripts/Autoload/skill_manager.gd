extends Node

# Sistema de árvore de habilidades, extraído do GameManager (Fase 6.3 da refatoração
# incremental). GameManager mantém propriedades e funções de encaminhamento para
# preservar 100% de compatibilidade com o código já existente (tower.gd, enemy.gd,
# ui.gd, skill_tree.gd, skill_node.gd), que continua chamando GameManager.has_skill(),
# GameManager.skill_unlocked, etc. normalmente.

signal skill_points_changed(new_amount: int)
signal skill_unlocked(skill_id: String)

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

	"esqueleto_mirada_alta": { "tower": "Esqueleto (Básico)", "stat": "range", "value": 30.0, "desc": "Aumenta o alcance em 30 e passa a priorizar os inimigos mais rápidos como alvo.", "requires": ["esqueleto_range_1"] },
	"esqueleto_estilhaco": { "tower": "Esqueleto (Básico)", "stat": "special", "value": 0.0, "desc": "Os projéteis causam dano em área (50% do dano) a inimigos num raio de 40 ao redor do alvo atingido.", "requires": ["esqueleto_damage_1"] },
	"esqueleto_arco_duplo": { "tower": "Esqueleto (Básico)", "stat": "special", "value": 0.0, "desc": "Dispara um segundo projétil simultâneo contra outro inimigo próximo.", "requires": ["esqueleto_spd_1"] },
	"esqueleto_chuva": { "tower": "Esqueleto (Básico)", "stat": "special", "value": 0.0, "desc": "A cada 5 ataques, dispara uma rajada em espiral de 4 a 6 projéteis simultâneos.", "requires": ["esqueleto_arco_duplo"], "exclusive_group": "esqueleto_tier3" },
	"esqueleto_maldicao": { "tower": "Esqueleto (Básico)", "stat": "special", "value": 0.0, "desc": "Os projéteis aplicam uma maldição que reduz a velocidade do inimigo em 15% por 3 segundos.", "requires": ["esqueleto_estilhaco"], "exclusive_group": "esqueleto_tier3" },
	"esqueleto_perfurante": { "tower": "Esqueleto (Básico)", "stat": "special", "value": 0.0, "desc": "Os projéteis perfuram e atingem até 3 inimigos antes de serem destruídos.", "requires": ["esqueleto_mirada_alta"], "exclusive_group": "esqueleto_tier3" },

	"fogo_base": { "tower": "Golem de Fogo (Chamas)", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },
	"sapo_base": { "tower": "Sapo (Sniper)", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },

	"olho_base": { "tower": "Olho Flutuante (Laser)", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },
	"olho_spd_1": { "tower": "Olho Flutuante (Laser)", "stat": "special", "value": 0.0, "desc": "Reduz o tempo entre disparos do laser para 0.10s.", "requires": ["olho_base"] },
	"olho_calor_1": { "tower": "Olho Flutuante (Laser)", "stat": "special", "value": 0.0, "desc": "Acumula até 4 cargas de calor (1 a cada segundo mirando o mesmo alvo); cada carga soma +1 de dano ao laser.", "requires": ["olho_spd_1"] },
	"olho_fusao": { "tower": "Olho Flutuante (Laser)", "stat": "special", "value": 0.0, "desc": "Ao atingir 4 cargas de calor, o próximo disparo causa o dobro de dano (fusão crítica).", "requires": ["olho_calor_1"], "exclusive_group": "olho_tier3" },

	"olho_dano_1": { "tower": "Olho Flutuante (Laser)", "stat": "special", "value": 0.0, "desc": "+1 de dano fixo por disparo do laser.", "requires": ["olho_base"] },
	"olho_bifurcado": { "tower": "Olho Flutuante (Laser)", "stat": "special", "value": 0.0, "desc": "O laser atinge um segundo alvo simultaneamente, mas o dano de cada disparo é reduzido para 70%.", "requires": ["olho_dano_1"] },
	"olho_cadeia": { "tower": "Olho Flutuante (Laser)", "stat": "special", "value": 0.0, "desc": "O laser ricocheteia para até 2 inimigos adicionais próximos de cada alvo atingido, causando o mesmo dano.", "requires": ["olho_bifurcado"], "exclusive_group": "olho_tier3" },

	"olho_range_1": { "tower": "Olho Flutuante (Laser)", "stat": "range", "value": 20.0, "requires": ["olho_base"] },
	"olho_instant": { "tower": "Olho Flutuante (Laser)", "stat": "special", "value": 0.0, "desc": "Elimina o tempo de trava de mira ao trocar de alvo e cada disparo reduz a velocidade do inimigo atingido em 15% por 0.5 segundos.", "requires": ["olho_range_1"] },
	"olho_satelite": { "tower": "Olho Flutuante (Laser)", "stat": "range", "value": 40.0, "desc": "Aumenta o alcance em 40 e marca o alvo atingido pela primeira vez, aumentando em 15% o dano físico recebido por 0.5 segundos.", "requires": ["olho_instant"], "exclusive_group": "olho_tier3" },

	"pedra_base": { "tower": "Golem de Pedra (Canhão)", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },

	"espantalho_base": { "tower": "Espantalho (Buff)", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },
	"espantalho_dano_1": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "desc": "Aumenta em 15% o dano das torres dentro do alcance do Espantalho.", "requires": ["espantalho_base"] },
	"espantalho_spd_1": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "desc": "Aumenta em 15% a velocidade de ataque e concede 10% de chance de crítico (dano dobrado) às torres no alcance.", "requires": ["espantalho_dano_1"] },
	"espantalho_frenesi": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "desc": "A cada 20 segundos, entra em frenesi por 5 segundos, dobrando (+100%) a velocidade de ataque das torres no alcance.", "requires": ["espantalho_spd_1"], "exclusive_group": "espantalho_tier3" },

	"espantalho_slow_1": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "desc": "Aplica uma lentidão de 2% aos inimigos que entram na área de influência do Espantalho.", "requires": ["espantalho_base"] },
	"espantalho_xp_1": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "desc": "Inimigos que morrem dentro da área do Espantalho concedem 20% mais XP.", "requires": ["espantalho_slow_1"] },
	"espantalho_panico": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "desc": "5% de chance de aplicar pânico nos inimigos que entram na área, fazendo-os recuar por 2 segundos.", "requires": ["espantalho_xp_1"], "exclusive_group": "espantalho_tier3" },

	"espantalho_range_1": { "tower": "Espantalho (Buff)", "stat": "range_pct", "value": 0.20, "requires": ["espantalho_base"] },
	"espantalho_range_buff": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "desc": "Aumenta em 5% o alcance e em 10% a velocidade dos projéteis das torres no alcance.", "requires": ["espantalho_range_1"] },
	"espantalho_sinergia": { "tower": "Espantalho (Buff)", "stat": "special", "value": 0.0, "desc": "Quando há 2 ou mais Espantalhos com esta skill no mesmo alcance, concede +2% adicional a todos os bônus (dano, velocidade de ataque, alcance e velocidade de projétil).", "requires": ["espantalho_range_buff"], "exclusive_group": "espantalho_tier3" },

	"gelo_base": { "tower": "Golem de Gelo (Lentidão)", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },
	"planta_base": { "tower": "Planta Peçonhenta", "stat": "unlock", "value": 1.0, "requires": ["base_start"] },

	"planta_dano_1": { "tower": "Planta Peçonhenta", "stat": "special", "value": 0.0, "desc": "Aumenta em 15% o dano de cada tique de veneno.", "requires": ["planta_base"] },
	"planta_stack_1": { "tower": "Planta Peçonhenta", "stat": "special", "value": 0.0, "desc": "Permite acumular até 3 pilhas de veneno no mesmo inimigo e aumenta a duração do veneno em 3 segundos.", "requires": ["planta_dano_1"] },
	"planta_necrose": { "tower": "Planta Peçonhenta", "stat": "special", "value": 0.0, "desc": "Ao atingir o limite de pilhas de veneno, a próxima aplicação causa instantaneamente todo o dano restante das pilhas acumuladas (necrose).", "requires": ["planta_stack_1"], "exclusive_group": "planta_tier3" },

	"planta_spd_1": { "tower": "Planta Peçonhenta", "stat": "fire_rate", "value": 0.20, "requires": ["planta_base"] },
	"planta_esporos": { "tower": "Planta Peçonhenta", "stat": "special", "value": 0.0, "desc": "A cada 15 segundos, libera uma nuvem de esporos em um ponto aleatório do caminho, envenenando inimigos que entrarem nela por 3 segundos.", "requires": ["planta_spd_1"] },
	"planta_epidemia": { "tower": "Planta Peçonhenta", "stat": "special", "value": 0.0, "desc": "Ao matar um inimigo envenenado, espalha o veneno restante (dividido por 3) para outros inimigos num raio de 80.", "requires": ["planta_esporos"], "exclusive_group": "planta_tier3" },

	"planta_range_1": { "tower": "Planta Peçonhenta", "stat": "range_pct", "value": 0.20, "requires": ["planta_base"] },
	"planta_neuro": { "tower": "Planta Peçonhenta", "stat": "special", "value": 0.0, "desc": "Inimigos envenenados recebem 10% mais dano físico e ficam 20% mais lentos enquanto durar o veneno.", "requires": ["planta_range_1"] },
	"planta_acido": { "tower": "Planta Peçonhenta", "stat": "special", "value": 0.0, "desc": "Cada tique de veneno causa dano adicional igual a 1.5% da vida máxima do inimigo.", "requires": ["planta_neuro"], "exclusive_group": "planta_tier3" },
}

func add_skill_point() -> void:
	skill_points += 1
	skill_points_changed.emit(skill_points)

func get_skill_tier(skill_id: String) -> int:
	if skill_id == "base_start": return -1
	if skill_id.ends_with("_base"): return 0

	var data = skill_tree_data.get(skill_id)
	if not data or data.requires.is_empty(): return 0

	var parent_tier = get_skill_tier(data.requires[0])
	return parent_tier + 1

func get_skill_cost(skill_id: String) -> int:
	var tier = get_skill_tier(skill_id)
	if tier <= 0: return 0
	if tier == 1: return 2
	if tier == 2: return 4
	if tier >= 3: return 6
	return 0

func _format_skill_number(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return str(value)

func get_skill_description(skill_id: String) -> String:
	var data = skill_tree_data.get(skill_id)
	if not data: return ""

	if data.has("desc"):
		return data.desc

	match data.stat:
		"unlock":
			return "Desbloqueia esta torre."
		"damage":
			return "+%s de dano por ataque." % _format_skill_number(data.value)
		"range":
			return "+%s de alcance." % _format_skill_number(data.value)
		"range_pct":
			return "+%d%% de alcance." % int(round(data.value * 100))
		"fire_rate":
			return "-%ss no tempo de recarga (ataques mais rápidos)." % _format_skill_number(data.value)
		"none":
			return "Ponto de partida da árvore de habilidades."
		_:
			return "Efeito especial."

func player_owns_tower(tower_name: String) -> bool:
	if InventoryManager.tower_inventory.get(tower_name, 0) > 0: return true
	var towers_in_game = get_tree().get_nodes_in_group("towers")
	for t in towers_in_game:
		if t.data and t.data.tower_name == tower_name:
			return true
	return false

func can_unlock_skill(skill_id: String) -> bool:
	if unlocked_skills.has(skill_id): return false

	var data = skill_tree_data.get(skill_id)
	if not data: return false

	for req in data.requires:
		if not unlocked_skills.has(req):
			return false

	if skill_id.ends_with("_base"):
		if not player_owns_tower(data.tower):
			return false

	if data.has("exclusive_group"):
		for other_id in unlocked_skills:
			var other_data = skill_tree_data.get(other_id)
			if other_data and other_data.has("exclusive_group") and other_data.exclusive_group == data.exclusive_group:
				return false

	return true

func buy_skill(skill_id: String) -> bool:
	if not can_unlock_skill(skill_id): return false

	var cost = get_skill_cost(skill_id)
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

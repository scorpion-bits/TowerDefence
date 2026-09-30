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
signal relocate_started(tower: Node2D)
signal skill_points_changed(new_amount: int)
signal skill_unlocked(skill_id: String)
signal shop_updated

var xp: int = 150
var lives: int = 20

func _ready() -> void:
	# Retransmite os sinais de SkillManager/InventoryManager por aqui, para não quebrar
	# quem já escuta GameManager.xxx diretamente. call_deferred evita qualquer
	# dependência da ordem de inicialização entre os autoloads.
	call_deferred("_connect_skill_manager_relay")
	call_deferred("_connect_inventory_manager_relay")

func _connect_skill_manager_relay() -> void:
	SkillManager.skill_points_changed.connect(func(amount): skill_points_changed.emit(amount))
	SkillManager.skill_unlocked.connect(func(skill_id): skill_unlocked.emit(skill_id))

func _connect_inventory_manager_relay() -> void:
	InventoryManager.inventory_changed.connect(func(): inventory_changed.emit())
	InventoryManager.item_dropped.connect(func(item_name): item_dropped.emit(item_name))
	InventoryManager.shop_updated.connect(func(): shop_updated.emit())

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

# --- CRAFTING / INVENTÁRIO / LOJA ---
# Dados e lógica foram extraídos para o autoload InventoryManager (Fase 6.4 da
# refatoração incremental). As propriedades e funções abaixo só encaminham para lá,
# preservando compatibilidade total com o código existente (ui.gd, level.gd,
# enemy.gd, skill_manager.gd), que continua chamando GameManager normalmente.

var tower_inventory: Dictionary:
	get: return InventoryManager.tower_inventory

var inventory: Dictionary:
	get: return InventoryManager.inventory

var recipes: Dictionary:
	get: return InventoryManager.recipes

var current_shop_item: String:
	get: return InventoryManager.current_shop_item

func roll_loot() -> void:
	InventoryManager.roll_loot()

func refresh_shop() -> void:
	InventoryManager.refresh_shop()

# --- SISTEMA DE ÁRVORE DE HABILIDADES ---
# Dados e lógica foram extraídos para o autoload SkillManager (Fase 6.3 da
# refatoração incremental). As propriedades e funções abaixo só encaminham para lá,
# preservando compatibilidade total com o código existente (tower.gd, enemy.gd,
# ui.gd, skill_tree.gd, skill_node.gd), que continua chamando GameManager normalmente.

var skill_points: int:
	get: return SkillManager.skill_points
	set(value): SkillManager.skill_points = value

var unlocked_skills: Dictionary:
	get: return SkillManager.unlocked_skills

var skill_tree_data: Dictionary:
	get: return SkillManager.skill_tree_data

func add_skill_point() -> void:
	SkillManager.add_skill_point()

func get_skill_tier(skill_id: String) -> int:
	return SkillManager.get_skill_tier(skill_id)

func get_skill_cost(skill_id: String) -> int:
	return SkillManager.get_skill_cost(skill_id)

func get_skill_description(skill_id: String) -> String:
	return SkillManager.get_skill_description(skill_id)

func can_unlock_skill(skill_id: String) -> bool:
	return SkillManager.can_unlock_skill(skill_id)

func buy_skill(skill_id: String) -> bool:
	return SkillManager.buy_skill(skill_id)

func get_tower_bonus(tower_name: String, stat: String) -> float:
	return SkillManager.get_tower_bonus(tower_name, stat)

func has_skill(skill_id: String) -> bool:
	return SkillManager.has_skill(skill_id)

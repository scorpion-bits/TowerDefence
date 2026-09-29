extends CanvasLayer

@onready var xp_label: Label = $Status/xpLabel
@onready var lives_label: Label = $Status/LivesLabel
@onready var wave_label: Label = $Wave/WaveCount

@onready var inventory_grid: GridContainer = $BuildPanel/TabContainer/Crafting/CraftVBox/InventoryGrid
@onready var slot0: Button = $BuildPanel/TabContainer/Crafting/CraftVBox/SlotsHBox/Slot0
@onready var slot1: Button = $BuildPanel/TabContainer/Crafting/CraftVBox/SlotsHBox/Slot1
@onready var slot2: Button = $BuildPanel/TabContainer/Crafting/CraftVBox/SlotsHBox/Slot2
@onready var result_slot: Button = $BuildPanel/TabContainer/Crafting/CraftVBox/SlotsHBox/ResultSlot
@onready var craft_button: Button = $BuildPanel/TabContainer/Crafting/CraftVBox/HBoxButtons/CraftButton
@onready var clear_button: Button = $BuildPanel/TabContainer/Crafting/CraftVBox/HBoxButtons/ClearButton

var current_crafting_items: Array[String] = []

@onready var game_over_panel: ColorRect = $GameOverPanel
@onready var restart_button: Button = $GameOverPanel/VBoxContainer/RestartButton

@onready var grid_container: GridContainer = $BuildPanel/TabContainer/Construir/ScrollContainer/GridContainer

@onready var start_wave_button: Button = $Functions/StartWaveButton
@onready var auto_start_checkbox: CheckBox = $Functions/AutoStartCheckbox
@onready var speed_checkbox: CheckBox = $Functions/SpeedCheckbox

# --- NOVO: Painel de Upgrades ---
@onready var upgrade_bar: VBoxContainer = $UpgradeBar
@onready var stats_label: Label = $UpgradeBar/StatsLabel
@onready var btn_upg_dmg: Button = $UpgradeBar/BtnDamage
@onready var btn_upg_spd: Button = $UpgradeBar/BtnSpeed
@onready var btn_upg_rng: Button = $UpgradeBar/BtnRange
@onready var btn_close_upg: Button = $UpgradeBar/BtnClose

var selected_tower: Node2D = null

func _ready() -> void:
	GameManager.xp_changed.connect(_on_xp_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.wave_updated.connect(_on_wave_updated)
	GameManager.tower_selected.connect(_on_tower_selected)
	GameManager.tower_deselected.connect(_on_tower_deselected)
	GameManager.game_over.connect(_on_game_over)
	GameManager.victory.connect(_on_victory)
	
	if restart_button: restart_button.pressed.connect(_on_restart_pressed)
	if craft_button: craft_button.pressed.connect(_on_craft_pressed)
	if clear_button: clear_button.pressed.connect(_on_clear_pressed)
	_update_inventory_ui()
	_update_crafting_slots()
	
	_on_xp_changed(GameManager.xp)
	_on_lives_changed(GameManager.lives)
	
	GameManager.tower_inventory_changed.connect(_load_towers)
	GameManager.inventory_changed.connect(_update_inventory_ui)
	_load_towers()
	
	if start_wave_button: start_wave_button.pressed.connect(_on_start_wave_pressed)
	if auto_start_checkbox: auto_start_checkbox.toggled.connect(_on_auto_start_toggled)
	if speed_checkbox: speed_checkbox.toggled.connect(func(pressed): Engine.time_scale = 2.0 if pressed else 1.0)
		
	if btn_upg_dmg: btn_upg_dmg.pressed.connect(func(): if selected_tower: selected_tower.upgrade_damage(); _update_upgrade_labels())
	if btn_upg_spd: btn_upg_spd.pressed.connect(func(): if selected_tower: selected_tower.upgrade_fire_rate(); _update_upgrade_labels())
	if btn_upg_rng: btn_upg_rng.pressed.connect(func(): if selected_tower: selected_tower.upgrade_range(); _update_upgrade_labels())
	if btn_close_upg: btn_close_upg.pressed.connect(func(): GameManager.tower_deselected.emit())
	
	_on_tower_deselected() # Esconde de inÃ­cio

func _on_tower_selected(tower: Node2D) -> void:
	selected_tower = tower
	$BuildPanel.hide()
	if upgrade_bar: upgrade_bar.show()
	_update_upgrade_labels()

func _on_tower_deselected() -> void:
	selected_tower = null
	if upgrade_bar: upgrade_bar.hide()
	$BuildPanel.show()

func _update_upgrade_labels() -> void:
	if not selected_tower: return
	
	if stats_label:
		stats_label.text = "Dano: %d\nTiros/s: %.1f\nAlcance: %d" % [
			selected_tower.data.attack_damage,
			1.0 / selected_tower.data.attack_cooldown,
			selected_tower.data.attack_range
		]
	
	var is_maxed = selected_tower.total_upgrades >= selected_tower.max_total_upgrades
	
	if btn_upg_dmg: 
		btn_upg_dmg.text = "Dano (Lvl " + str(selected_tower.damage_level) + ") - $" + str(selected_tower.get_damage_cost())
		btn_upg_dmg.disabled = is_maxed
	if btn_upg_spd: 
		btn_upg_spd.text = "Veloc. (Lvl " + str(selected_tower.fire_rate_level) + ") - $" + str(selected_tower.get_fire_rate_cost())
		btn_upg_spd.disabled = is_maxed
	if btn_upg_rng: 
		btn_upg_rng.text = "Raio (Lvl " + str(selected_tower.range_level) + ") - $" + str(selected_tower.get_range_cost())
		btn_upg_rng.disabled = is_maxed

	if is_maxed:
		if btn_upg_dmg: btn_upg_dmg.text = "Dano (MAX)"
		if btn_upg_spd: btn_upg_spd.text = "Veloc. (MAX)"
		if btn_upg_rng: btn_upg_rng.text = "Raio (MAX)"

func _on_start_wave_pressed() -> void:
	GameManager.start_wave_requested.emit()

func _on_auto_start_toggled(button_pressed: bool) -> void:
	GameManager.auto_start_toggled.emit(button_pressed)


func _on_xp_changed(new_amount: int) -> void:
	if xp_label: xp_label.text = "XP: " + str(new_amount)

func _on_lives_changed(new_amount: int) -> void:
	if lives_label: lives_label.text = "Vidas: " + str(new_amount)
	
func _on_wave_updated(wave_num: int) -> void:
	if wave_label: wave_label.text = "Onda: " + str(wave_num)

func _on_game_over() -> void:
	if game_over_panel: 
		game_over_panel.show()
		game_over_panel.get_node("VBoxContainer/Label").text = "GAME OVER"
	get_tree().paused = true

func _on_victory() -> void:
	if game_over_panel: 
		game_over_panel.show()
		game_over_panel.get_node("VBoxContainer/Label").text = "VITÓRIA!"
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.xp = 150
	GameManager.lives = 20
	get_tree().reload_current_scene()


func _load_towers() -> void:
	# Limpar botões antigos de placeholder na cena
	for child in grid_container.get_children():
		child.queue_free()
		
	var dir = DirAccess.open("res://resources/towers/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var data = load("res://resources/towers/" + file_name) as TowerData
				if data:
					_create_tower_button(data)
			file_name = dir.get_next()

func _create_tower_button(data: TowerData) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(85, 85)
	
	var amount = GameManager.tower_inventory.get(data.tower_name, 0)
	var short_name = data.tower_name.split(" ")[0]
	btn.text = "%s\n(%d)" % [short_name, amount]

	if amount > 0:
		btn.tooltip_text = "Dano: %d\nVelocidade: %.1f\nAlcance: %d" % [data.attack_damage, 1.0/data.attack_cooldown, data.attack_range]
		btn.disabled = false
	else:
		var req = GameManager.recipes.get(data.tower_name, [])
		btn.tooltip_text = "RECEITA:\n" + ", ".join(req)
		btn.disabled = true

	btn.button_down.connect(func(): GameManager.drag_started.emit(data))
	grid_container.add_child(btn)






func _update_inventory_ui() -> void:
	if not inventory_grid: return
	for c in inventory_grid.get_children():
		c.queue_free()
	
	for item in GameManager.inventory:
		var amount = GameManager.inventory[item]
		if amount > 0:
			var btn = Button.new()
			btn.text = "%s (%d)" % [item.substr(0, 3), amount]
			btn.tooltip_text = item
			btn.custom_minimum_size = Vector2(40, 40)
			btn.pressed.connect(func(): _on_inventory_item_clicked(item))
			inventory_grid.add_child(btn)

func _on_inventory_item_clicked(item: String) -> void:
	if current_crafting_items.size() < 3:
		current_crafting_items.append(item)
		_update_crafting_slots()

func _on_clear_pressed() -> void:
	current_crafting_items.clear()
	_update_crafting_slots()

func _update_crafting_slots() -> void:
	var slots = [slot0, slot1, slot2]
	for i in range(3):
		if i < current_crafting_items.size():
			slots[i].text = current_crafting_items[i].substr(0, 3)
		else:
			slots[i].text = ""
			
	var result = _check_recipe()
	if result != "":
		result_slot.text = result
	else:
		result_slot.text = ""

func _check_recipe() -> String:
	# Sort to make order independent
	var current_sorted = current_crafting_items.duplicate()
	current_sorted.sort()
	
	for tower_name in GameManager.recipes:
		var req = GameManager.recipes[tower_name].duplicate()
		req.sort()
		if current_sorted == req:
			return tower_name
	return ""

func _on_craft_pressed() -> void:
	var result = _check_recipe()
	if result != "":
		GameManager.tower_inventory[result] = GameManager.tower_inventory.get(result, 0) + 1
		for item in current_crafting_items:
			GameManager.inventory[item] -= 1
		current_crafting_items.clear()
		_update_crafting_slots()
		_update_inventory_ui()
		GameManager.tower_inventory_changed.emit()

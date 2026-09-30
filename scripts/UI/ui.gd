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
@onready var recipes_vbox: VBoxContainer = $BuildPanel/TabContainer/Receitas/ScrollContainer/RecipesVBox

@onready var start_wave_button: Button = $Functions/StartWaveButton
@onready var auto_start_checkbox: CheckBox = $Functions/AutoStartCheckbox
@onready var speed_checkbox: CheckBox = $Functions/SpeedCheckbox


@onready var upgrade_bar: VBoxContainer = $UpgradeBar
@onready var stats_label: Label = $UpgradeBar/StatsLabel

@onready var btn_close_upg: Button = $UpgradeBar/BtnClose
@onready var btn_sell_tower: Button = $UpgradeBar/BtnSell

var selected_tower: Node2D = null

var sp_label: Label
var btn_move: Button

func _ready() -> void:
	if upgrade_bar:
		btn_move = Button.new()
		btn_move.text = "Mover Torre"
		upgrade_bar.add_child(btn_move)
		upgrade_bar.move_child(btn_move, 2)
		btn_move.pressed.connect(_on_move_tower_pressed)

	if has_node("BtnCheat"):
		$BtnCheat.pressed.connect(_on_cheat_pressed)
		
	if has_node("Status"):
		sp_label = Label.new()
		sp_label.text = "SP: 0"
		$Status.add_child(sp_label)

	GameManager.xp_changed.connect(_on_xp_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.skill_points_changed.connect(_on_sp_changed)
	GameManager.wave_updated.connect(_on_wave_updated)
	GameManager.tower_selected.connect(_on_tower_selected)
	GameManager.tower_deselected.connect(_on_tower_deselected)
	GameManager.game_over.connect(_on_game_over)
	GameManager.victory.connect(_on_victory)
	GameManager.item_dropped.connect(_on_item_dropped)
	
	if restart_button: restart_button.pressed.connect(_on_restart_pressed)
	if craft_button: craft_button.pressed.connect(_on_craft_pressed)
	if clear_button: clear_button.pressed.connect(_on_clear_pressed)
	_update_inventory_ui()
	_update_crafting_slots()
	
	_on_xp_changed(GameManager.xp)
	_on_lives_changed(GameManager.lives)
	_on_sp_changed(GameManager.skill_points)
	
	GameManager.tower_inventory_changed.connect(_load_towers)
	GameManager.inventory_changed.connect(_update_inventory_ui)
	_load_towers()
	_load_recipes()
	
	if start_wave_button: start_wave_button.pressed.connect(_on_start_wave_pressed)
	if auto_start_checkbox: auto_start_checkbox.toggled.connect(_on_auto_start_toggled)
	if speed_checkbox: speed_checkbox.toggled.connect(func(pressed): Engine.time_scale = 2.0 if pressed else 1.0)
		

	if btn_close_upg: btn_close_upg.pressed.connect(func(): GameManager.tower_deselected.emit())
	if btn_sell_tower: btn_sell_tower.pressed.connect(_on_sell_tower_pressed)
	if has_node("BtnSkillTree"): $BtnSkillTree.pressed.connect(_on_btn_skill_tree_pressed)
	
	_setup_mercado()
	
	_on_tower_deselected() # Esconde de início

func _on_sell_tower_pressed() -> void:
	if selected_tower and is_instance_valid(selected_tower):
		var tower_name = selected_tower.data.tower_name
		GameManager.tower_inventory[tower_name] = GameManager.tower_inventory.get(tower_name, 0) + 1
		GameManager.tower_inventory_changed.emit()
		selected_tower.queue_free()
		GameManager.tower_deselected.emit()

func _on_move_tower_pressed() -> void:
	if selected_tower and is_instance_valid(selected_tower):
		GameManager.relocate_started.emit(selected_tower)
		GameManager.tower_deselected.emit()

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
			selected_tower.get_current_damage(),
			1.0 / selected_tower.get_current_cooldown(),
			selected_tower.get_current_range()
		]

func _on_start_wave_pressed() -> void:
	GameManager.start_wave_requested.emit()

func _on_auto_start_toggled(button_pressed: bool) -> void:
	GameManager.auto_start_toggled.emit(button_pressed)


func _on_xp_changed(new_amount: int) -> void:
	if xp_label: xp_label.text = "XP: " + str(new_amount)

func _on_lives_changed(new_amount: int) -> void:
	if lives_label: lives_label.text = "Vidas: " + str(new_amount)

func _on_sp_changed(new_amount: int) -> void:
	if sp_label: sp_label.text = "SP: " + str(new_amount)
	
func _on_wave_updated(wave_num: int) -> void:
	if wave_label: wave_label.text = "Onda: " + str(wave_num)
	GameManager.refresh_shop()

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
			
		var needed = {}
		for item in current_crafting_items:
			needed[item] = needed.get(item, 0) + 1
			
		var can_keep = true
		for item in needed:
			if GameManager.inventory.get(item, 0) < needed[item]:
				can_keep = false
				break
				
		if not can_keep:
			current_crafting_items.clear()
			
		_update_crafting_slots()
		_update_inventory_ui()
		GameManager.tower_inventory_changed.emit()

func _load_recipes() -> void:
	if not recipes_vbox: return
	
	for child in recipes_vbox.get_children():
		child.queue_free()
		
	for tower_name in GameManager.recipes:
		var req = GameManager.recipes[tower_name]
		var label = Label.new()
		label.text = tower_name + ":\n  " + " + ".join(req)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		recipes_vbox.add_child(label)
		
		var sep = HSeparator.new()
		recipes_vbox.add_child(sep)

func _on_item_dropped(item_name: String) -> void:
	var label = Label.new()
	label.text = "+1 " + item_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(300, 50)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2, 1)) # Green color
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	
	# Position near center top, with some randomness
	var viewport_size = get_viewport().get_visible_rect().size
	var rx = randf_range(-40.0, 40.0)
	var ry = randf_range(-20.0, 20.0)
	label.position = Vector2((viewport_size.x / 2.0) - 150.0 + rx, (viewport_size.y / 2.0) - 150.0 + ry)
	
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 80.0, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.5).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)

var skill_tree_scene = preload("res://scenes/skill_tree.tscn")
var skill_tree_instance: CanvasLayer = null

func _on_btn_skill_tree_pressed():
	if not skill_tree_instance:
		skill_tree_instance = skill_tree_scene.instantiate()
		add_child(skill_tree_instance)
	skill_tree_instance.show()
	get_tree().paused = true

func _on_cheat_pressed() -> void:
	var dir = DirAccess.open("res://resources/towers/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var data = load("res://resources/towers/" + file_name) as TowerData
				if data:
					GameManager.tower_inventory[data.tower_name] = 10
			file_name = dir.get_next()
			
	for item in GameManager.inventory.keys():
		GameManager.inventory[item] = 99
		
	GameManager.skill_points += 99
	GameManager.skill_points_changed.emit(GameManager.skill_points)
	
	GameManager.tower_inventory_changed.emit()
	GameManager.inventory_changed.emit()
	
	GameManager.xp += 10000
	GameManager.xp_changed.emit(GameManager.xp)

var mercado_tab: MarginContainer
var btn_buy_specific: Button
var btn_buy_chest: Button

func _setup_mercado() -> void:
	if not has_node("BuildPanel/TabContainer"): return
	
	mercado_tab = MarginContainer.new()
	mercado_tab.name = "Mercado"
	mercado_tab.add_theme_constant_override("margin_left", 10)
	mercado_tab.add_theme_constant_override("margin_top", 10)
	mercado_tab.add_theme_constant_override("margin_right", 10)
	mercado_tab.add_theme_constant_override("margin_bottom", 10)
	
	var vbox = VBoxContainer.new()
	mercado_tab.add_child(vbox)
	
	var title = Label.new()
	title.text = "Gaste XP por Materiais"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer1)
	
	btn_buy_specific = Button.new()
	btn_buy_specific.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(btn_buy_specific)
	btn_buy_specific.pressed.connect(_on_buy_specific)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer2)
	
	btn_buy_chest = Button.new()
	btn_buy_chest.text = "Baú Misterioso\n(Custo: 1000 XP)\nChance de Vir Qualquer Material"
	btn_buy_chest.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(btn_buy_chest)
	btn_buy_chest.pressed.connect(_on_buy_chest)
	
	$BuildPanel/TabContainer.add_child(mercado_tab)
	
	GameManager.shop_updated.connect(_update_mercado_ui)
	GameManager.xp_changed.connect(_update_mercado_buttons)
	_update_mercado_ui()

func _update_mercado_ui() -> void:
	if GameManager.current_shop_item == "":
		if btn_buy_specific: btn_buy_specific.text = "Nenhum material na loja..."
	else:
		if btn_buy_specific: btn_buy_specific.text = "Comprar: %s\n(Custo: 2000 XP)" % GameManager.current_shop_item
	_update_mercado_buttons(GameManager.xp)

func _update_mercado_buttons(current_xp: int) -> void:
	if btn_buy_specific:
		btn_buy_specific.disabled = (current_xp < 2000) or (GameManager.current_shop_item == "")
	if btn_buy_chest:
		btn_buy_chest.disabled = (current_xp < 1000)

func _on_buy_specific() -> void:
	if GameManager.spend_xp(2000):
		if GameManager.current_shop_item != "":
			GameManager.inventory[GameManager.current_shop_item] += 1
			GameManager.inventory_changed.emit()
			GameManager.item_dropped.emit(GameManager.current_shop_item)

func _on_buy_chest() -> void:
	if GameManager.spend_xp(1000):
		# 60% chance to get something, 40% chance nothing
		if randf() < 0.60:
			var items = GameManager.inventory.keys()
			if items.size() > 0:
				var item = items[randi() % items.size()]
				GameManager.inventory[item] += 1
				GameManager.inventory_changed.emit()
				GameManager.item_dropped.emit(item)
		else:
			GameManager.item_dropped.emit("Vento... (Nada!)")

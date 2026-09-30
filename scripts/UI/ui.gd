extends CanvasLayer

const CraftingController = preload("res://scripts/UI/crafting_controller.gd")
const TowerShopController = preload("res://scripts/UI/tower_shop_controller.gd")
const UpgradeBarController = preload("res://scripts/UI/upgrade_bar_controller.gd")
const ShopMercadoController = preload("res://scripts/UI/shop_mercado_controller.gd")

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

var sp_label: Label

var crafting_controller: CraftingController
var tower_shop_controller: TowerShopController
var upgrade_bar_controller: UpgradeBarController
var mercado_controller: ShopMercadoController

func _ready() -> void:
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

	crafting_controller = CraftingController.new(
		inventory_grid, slot0, slot1, slot2, result_slot, recipes_vbox, craft_button, clear_button
	)

	_on_xp_changed(GameManager.xp)
	_on_lives_changed(GameManager.lives)
	_on_sp_changed(GameManager.skill_points)

	tower_shop_controller = TowerShopController.new(grid_container)

	if start_wave_button: start_wave_button.pressed.connect(_on_start_wave_pressed)
	if auto_start_checkbox: auto_start_checkbox.toggled.connect(_on_auto_start_toggled)
	if speed_checkbox: speed_checkbox.toggled.connect(func(pressed): Engine.time_scale = 2.0 if pressed else 1.0)

	upgrade_bar_controller = UpgradeBarController.new(upgrade_bar, stats_label, btn_close_upg, btn_sell_tower)
	if has_node("BtnSkillTree"): $BtnSkillTree.pressed.connect(_on_btn_skill_tree_pressed)

	if has_node("BuildPanel/TabContainer"):
		mercado_controller = ShopMercadoController.new($BuildPanel/TabContainer)

	_on_tower_deselected() # Esconde de início

func _on_tower_selected(tower: Node2D) -> void:
	$BuildPanel.hide()
	upgrade_bar_controller.show_for(tower)

func _on_tower_deselected() -> void:
	upgrade_bar_controller.hide_panel()
	$BuildPanel.show()

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

extends CanvasLayer

@onready var gold_label: Label = $Status/GoldLabel
@onready var lives_label: Label = $Status/LivesLabel
@onready var wave_label: Label = $Wave/WaveCount

@onready var basic_tower_button: Button = $SideBar/BtnBasic
@export var basic_tower_data: TowerData

@onready var sniper_tower_button: Button = $SideBar/BtnSniper
@export var sniper_tower_data: TowerData

@onready var mg_tower_button: Button = $SideBar/BtnMG
@export var mg_tower_data: TowerData

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
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.wave_updated.connect(_on_wave_updated)
	GameManager.tower_selected.connect(_on_tower_selected)
	GameManager.tower_deselected.connect(_on_tower_deselected)
	
	_on_gold_changed(GameManager.gold)
	_on_lives_changed(GameManager.lives)
	
	if basic_tower_button: basic_tower_button.button_down.connect(func(): if basic_tower_data: GameManager.drag_started.emit(basic_tower_data))
	if sniper_tower_button: sniper_tower_button.button_down.connect(func(): if sniper_tower_data: GameManager.drag_started.emit(sniper_tower_data))
	if mg_tower_button: mg_tower_button.button_down.connect(func(): if mg_tower_data: GameManager.drag_started.emit(mg_tower_data))
	
	if start_wave_button: start_wave_button.pressed.connect(_on_start_wave_pressed)
	if auto_start_checkbox: auto_start_checkbox.toggled.connect(_on_auto_start_toggled)
	if speed_checkbox: speed_checkbox.toggled.connect(func(pressed): Engine.time_scale = 2.0 if pressed else 1.0)
		
	if btn_upg_dmg: btn_upg_dmg.pressed.connect(func(): if selected_tower: selected_tower.upgrade_damage(); _update_upgrade_labels())
	if btn_upg_spd: btn_upg_spd.pressed.connect(func(): if selected_tower: selected_tower.upgrade_fire_rate(); _update_upgrade_labels())
	if btn_upg_rng: btn_upg_rng.pressed.connect(func(): if selected_tower: selected_tower.upgrade_range(); _update_upgrade_labels())
	if btn_close_upg: btn_close_upg.pressed.connect(func(): GameManager.tower_deselected.emit())
	
	_on_tower_deselected() # Esconde de início

func _on_tower_selected(tower: Node2D) -> void:
	selected_tower = tower
	$SideBar.hide()
	if upgrade_bar: upgrade_bar.show()
	_update_upgrade_labels()

func _on_tower_deselected() -> void:
	selected_tower = null
	if upgrade_bar: upgrade_bar.hide()
	$SideBar.show()

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

func _on_basic_tower_button_down() -> void:
	if basic_tower_data:
		GameManager.drag_started.emit(basic_tower_data)

func _on_gold_changed(new_amount: int) -> void:
	if gold_label: gold_label.text = "Grana: " + str(new_amount)

func _on_lives_changed(new_amount: int) -> void:
	if lives_label: lives_label.text = "Vidas: " + str(new_amount)
	
func _on_wave_updated(wave_num: int) -> void:
	if wave_label: wave_label.text = "Onda: " + str(wave_num)

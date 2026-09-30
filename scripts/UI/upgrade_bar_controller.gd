extends RefCounted

# Controla o painel de upgrade/venda/movimentação da torre selecionada. Extraído de
# ui.gd (Fase 6.5 da refatoração incremental). RefCounted, não Node — não precisa de
# mudança em ui.tscn. ui.gd continua responsável por mostrar/esconder o BuildPanel.

var upgrade_bar: VBoxContainer
var stats_label: Label
var selected_tower: Node2D = null

func _init(p_upgrade_bar: VBoxContainer, p_stats_label: Label, btn_close: Button, btn_sell: Button) -> void:
	upgrade_bar = p_upgrade_bar
	stats_label = p_stats_label

	if upgrade_bar:
		var btn_move = Button.new()
		btn_move.text = "Mover Torre"
		upgrade_bar.add_child(btn_move)
		upgrade_bar.move_child(btn_move, 2)
		btn_move.pressed.connect(_on_move_tower_pressed)

	if btn_close: btn_close.pressed.connect(func(): GameManager.tower_deselected.emit())
	if btn_sell: btn_sell.pressed.connect(_on_sell_tower_pressed)

func show_for(tower: Node2D) -> void:
	selected_tower = tower
	if upgrade_bar: upgrade_bar.show()
	_update_upgrade_labels()

func hide_panel() -> void:
	selected_tower = null
	if upgrade_bar: upgrade_bar.hide()

func _update_upgrade_labels() -> void:
	if not selected_tower: return

	if stats_label:
		stats_label.text = "Dano: %d\nTiros/s: %.1f\nAlcance: %d" % [
			selected_tower.get_current_damage(),
			1.0 / selected_tower.get_current_cooldown(),
			selected_tower.get_current_range()
		]

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

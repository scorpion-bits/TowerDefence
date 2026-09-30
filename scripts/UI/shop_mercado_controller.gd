extends RefCounted

# Controla a aba "Mercado" (gastar XP por materiais). Extraído de ui.gd (Fase 6.5 da
# refatoração incremental). RefCounted, não Node — constrói sua própria UI dinâmica
# dentro do TabContainer recebido, sem precisar de mudança em ui.tscn.

var btn_buy_specific: Button
var btn_buy_chest: Button

func _init(tab_container: TabContainer) -> void:
	var mercado_tab = MarginContainer.new()
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

	tab_container.add_child(mercado_tab)

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

extends RefCounted

# Controla a grade de compra/arraste de torres (aba "Construir"). Extraído de ui.gd
# (Fase 6.5 da refatoração incremental). RefCounted, não Node — não precisa de
# mudança em ui.tscn.

var grid_container: GridContainer

func _init(p_grid_container: GridContainer) -> void:
	grid_container = p_grid_container
	GameManager.tower_inventory_changed.connect(_load_towers)
	_load_towers()

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

extends Node2D

@export var tower_scene: PackedScene
@export var ghost_scene: PackedScene

var current_ghost: Node2D
var dragging_data: TowerData

func _ready() -> void:
	GameManager.drag_started.connect(_on_drag_started)

func _on_drag_started(data: TowerData) -> void:
	if not ghost_scene: 
		print("Faltou colocar a cena do Ghost no Level!")
		return
		
	dragging_data = data
	current_ghost = ghost_scene.instantiate()
	add_child(current_ghost)
	current_ghost.setup(data)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Quando SOLTAR o botão esquerdo do mouse (tentando construir)
		if not event.pressed:
			if current_ghost:
				_try_build_tower()
		
		# Quando APERTAR o botão esquerdo do mouse no mapa livre
		if event.pressed:
			if not current_ghost:
				GameManager.tower_deselected.emit()

func _try_build_tower() -> void:
	if current_ghost.is_valid_location:
		var amount = GameManager.tower_inventory.get(dragging_data.tower_name, 0)
		if amount > 0:
			GameManager.tower_inventory[dragging_data.tower_name] = amount - 1
			GameManager.tower_inventory_changed.emit()
			var new_tower = tower_scene.instantiate()
			new_tower.data = dragging_data.duplicate()
			new_tower.global_position = current_ghost.global_position
			add_child(new_tower)
			
	_cancel_drag()

func _cancel_drag() -> void:
	if current_ghost:
		current_ghost.queue_free()
		current_ghost = null
		dragging_data = null

extends Node2D

@export var tower_scene: PackedScene
@export var ghost_scene: PackedScene

var current_ghost: Node2D
var dragging_data: TowerData
var relocating_tower: Node2D

func _ready() -> void:
	GameManager.drag_started.connect(_on_drag_started)
	GameManager.relocate_started.connect(_on_relocate_started)

func _on_drag_started(data: TowerData) -> void:
	if not ghost_scene: return
	if is_instance_valid(current_ghost): current_ghost.queue_free()
		
	dragging_data = data
	current_ghost = ghost_scene.instantiate()
	add_child(current_ghost)
	current_ghost.setup(data)

func _on_relocate_started(tower: Node2D) -> void:
	if not ghost_scene: return
	if is_instance_valid(current_ghost): current_ghost.queue_free()
	
	relocating_tower = tower
	relocating_tower.hide()
	
	current_ghost = ghost_scene.instantiate()
	add_child(current_ghost)
	current_ghost.setup(tower.data)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			if is_instance_valid(current_ghost):
				_try_build_tower()
		
		if event.pressed:
			if not is_instance_valid(current_ghost):
				GameManager.tower_deselected.emit()
				
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_cancel_drag()

func _try_build_tower() -> void:
	if current_ghost.is_valid_location:
		if is_instance_valid(relocating_tower):
			relocating_tower.global_position = current_ghost.global_position
			relocating_tower.show()
			# Atualiza stats/buffs pela nova area
			if relocating_tower.has_method("_update_stats"):
				relocating_tower._update_stats()
			relocating_tower = null
			_cancel_drag()
			return
			
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

	if is_instance_valid(relocating_tower):
		relocating_tower.show()
		# Reativa o ataque (parado em _on_relocate_started_global) caso a realocação seja
		# cancelada ou solta num local inválido, em vez de concluída em _try_build_tower().
		if relocating_tower.has_method("_update_stats"):
			relocating_tower._update_stats()
		relocating_tower = null

extends Node2D

@export var tower_scene: PackedScene
@export var ghost_scene: PackedScene

var current_ghost: Node2D
var dragging_data: TowerData

func _ready() -> void:
	# Escuta o sinal global de quando começamos a arrastar algo
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
	# Checa se o fantasma tá vermelho (is_valid_location = false)
	if not current_ghost.is_valid_location:
		print("Local bloqueado!")
		_cancel_drag()
		return
		
	# Checa se tem grana
	if not GameManager.spend_gold(dragging_data.cost):
		print("sem grana")
		_cancel_drag()
		return
		
	# Se tudo deu certo, cria a torre
	var tower = tower_scene.instantiate()
	
	# Passa os dados DUPLICADOS para a torre ANTES de adicionar à cena
	# para que o _ready() dela já rode com os dados certos e individuais!
	tower.data = dragging_data.duplicate()
	tower.global_position = current_ghost.global_position
	
	add_child(tower)
	print("torre colocada em ", tower.global_position)
	_cancel_drag()

func _cancel_drag() -> void:
	if current_ghost:
		current_ghost.queue_free()
		current_ghost = null
		dragging_data = null

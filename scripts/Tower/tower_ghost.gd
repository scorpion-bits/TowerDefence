extends Node2D

var tower_data: TowerData
var is_valid_location: bool = true
var overlapping_count: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_area: Area2D = $CollisionArea

func _ready() -> void:
	collision_area.area_entered.connect(_on_area_entered)
	collision_area.area_exited.connect(_on_area_exited)
	
	# Para detectar o TileMap (que é um Body, e não uma Area)
	collision_area.body_entered.connect(_on_body_entered)
	collision_area.body_exited.connect(_on_body_exited)

func setup(data: TowerData) -> void:
	tower_data = data
	if sprite: 
		sprite.modulate = data.color
		sprite.modulate.a = 0.6 # Fica meio transparente
	queue_redraw()

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()
	
	# Se estiver colidindo com algo OU se estiver sem grana, fica vermelho
	if overlapping_count > 0 :
		is_valid_location = false
		sprite.modulate = Color.RED
		sprite.modulate.a = 0.6
	else:
		is_valid_location = true
		sprite.modulate = tower_data.color
		sprite.modulate.a = 0.6

func _draw() -> void:
	# Desenha o círculo de alcance da torre
	if tower_data:
		draw_circle(Vector2.ZERO, tower_data.attack_range, Color(0.2, 0.8, 1.0, 0.3))

func _on_area_entered(_area: Area2D) -> void:
	overlapping_count += 1

func _on_area_exited(_area: Area2D) -> void:
	overlapping_count -= 1

func _on_body_entered(_body: Node2D) -> void:
	overlapping_count += 1

func _on_body_exited(_body: Node2D) -> void:
	overlapping_count -= 1

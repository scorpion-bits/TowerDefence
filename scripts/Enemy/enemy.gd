extends PathFollow2D

@export var data: EnemyData
@onready var health_component: HealthComponent = $HealthComponent
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if data:
		health_component.max_health = data.max_health
		health_component.current_health = data.max_health
		if sprite: sprite.modulate = data.color
			
	if health_component:
		health_component.died.connect(_on_died)

func _process(delta: float) -> void:
	if data:
		progress += data.speed * delta
		
		if progress_ratio >= 1.0:
			_reach_end()

func _on_died() -> void:
	GameManager.add_gold(data.reward)
	queue_free()

func _reach_end() -> void:
	GameManager.take_damage(data.damage_to_player)
	queue_free()

extends PathFollow2D

@export var data: EnemyData

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
	loop = false
	if data:
		health_component.max_health = data.max_health
		health_component.current_health = data.max_health
		
		if anim_sprite and data.sprite_frames:
			anim_sprite.sprite_frames = data.sprite_frames
			anim_sprite.play("default")
		elif anim_sprite:
			anim_sprite.modulate = data.color
			
	if health_component:
		health_component.died.connect(_on_died)

func _process(delta: float) -> void:
	if data:
		progress += data.speed * delta
		
		if progress_ratio >= 1.0:
			_reach_end()

func _on_died() -> void:
	GameManager.add_xp(data.reward)
	GameManager.roll_loot()
	queue_free()

func _reach_end() -> void:
	GameManager.take_damage(data.damage_to_player)
	queue_free()

extends PathFollow2D

@export var data: EnemyData

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $HealthComponent

var speed_modifier: float = 1.0

var burn_damage: int = 0
var burn_time_left: float = 0.0
var burn_tick_timer: float = 0.0

var poison_damage: int = 0
var poison_time_left: float = 0.0
var poison_tick_timer: float = 0.0

var slow_sources: int = 0

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
		var current_speed = data.speed * speed_modifier
		progress += current_speed * delta
		
		if progress_ratio >= 1.0:
			_reach_end()

	if burn_time_left > 0:
		burn_time_left -= delta
		burn_tick_timer -= delta
		if burn_tick_timer <= 0.0:
			burn_tick_timer = 1.0
			health_component.take_damage(burn_damage)
			
	if poison_time_left > 0:
		poison_time_left -= delta
		poison_tick_timer -= delta
		if poison_tick_timer <= 0.0:
			poison_tick_timer = 1.0
			health_component.take_damage(poison_damage)
	
	_update_visuals()

func add_slow(amount: float) -> void:
	slow_sources += 1
	speed_modifier = amount

func remove_slow() -> void:
	slow_sources -= 1
	if slow_sources <= 0:
		slow_sources = 0
		speed_modifier = 1.0

func apply_burn(dmg: int, duration: float) -> void:
	burn_damage = max(burn_damage, dmg)
	burn_time_left = max(burn_time_left, duration)
	if burn_tick_timer <= 0:
		burn_tick_timer = 1.0

func apply_poison(dmg: int, duration: float) -> void:
	poison_damage = max(poison_damage, dmg)
	poison_time_left = max(poison_time_left, duration)
	if poison_tick_timer <= 0:
		poison_tick_timer = 1.0

func _update_visuals() -> void:
	if not data or not anim_sprite: return
	if burn_time_left > 0:
		anim_sprite.modulate = Color(1.0, 0.3, 0.0)
	elif poison_time_left > 0:
		anim_sprite.modulate = Color(0.6, 0.2, 0.8) # Purple for poison
	elif slow_sources > 0:
		anim_sprite.modulate = Color(0.3, 0.6, 1.0)
	else:
		if not data.sprite_frames:
			anim_sprite.modulate = data.color
		else:
			anim_sprite.modulate = Color.WHITE

func _on_died() -> void:
	GameManager.add_xp(data.reward)
	GameManager.roll_loot()
	queue_free()

func _reach_end() -> void:
	GameManager.take_damage(data.damage_to_player)
	queue_free()

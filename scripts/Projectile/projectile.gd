extends Node2D

@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var sprite: Sprite2D = $Sprite2D

var target: Node2D
var speed: float = 300.0

func _ready() -> void:
	if hitbox_component:
		hitbox_component.dealt_damage.connect(_on_dealt_damage)

var effect_type: String = ""
var effect_value: float = 0.0

func setup(_target: Node2D, _damage: int, _speed: float, _color: Color, _eff: String = "", _eval: float = 0.0) -> void:
	effect_type = _eff
	effect_value = _eval
	target = _target
	speed = _speed
	if hitbox_component: hitbox_component.damage = _damage
	if sprite: sprite.modulate = _color

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
		
	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta
	rotation = direction.angle()

func _apply_effect(enemy: Node2D) -> void:
	if effect_type == "slow_hit":
		if "speed" in enemy.data:
			var old_speed = enemy.data.speed
			enemy.data.speed = old_speed * effect_value
			await get_tree().create_timer(3.0).timeout
			if is_instance_valid(enemy): enemy.data.speed = old_speed
	elif effect_type == "instakill":
		var is_boss = enemy.scale.x > 1.2
		if not is_boss and enemy.has_node("HealthComponent"):
			enemy.get_node("HealthComponent").take_damage(99999)
	elif effect_type == "ice_aoe":
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and e.global_position.distance_to(enemy.global_position) < 80.0:
				if "speed" in e.data:
					e.data.speed *= effect_value
	elif effect_type == "fire_path" or effect_type == "poison_path":
		if enemy.has_node("HealthComponent"):
			enemy.get_node("HealthComponent").take_damage(int(effect_value))
	elif effect_type == "esqueleto_estilhaco":
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and e != enemy and e.global_position.distance_to(enemy.global_position) < 40.0:
				if e.has_node("HealthComponent"):
					e.get_node("HealthComponent").take_damage(int(hitbox_component.damage * 0.5))
	elif effect_type == "esqueleto_maldicao":
		if "speed" in enemy.data:
			var old_speed = enemy.data.speed
			enemy.data.speed = old_speed * 0.85
			await get_tree().create_timer(3.0).timeout
			if is_instance_valid(enemy): enemy.data.speed = old_speed

var pierce_count = 3
func _on_dealt_damage(hurtbox: HurtboxComponent) -> void:
	if hurtbox.owner:
		_apply_effect(hurtbox.owner)

	if effect_type == "esqueleto_perfurante":
		pierce_count -= 1
		if pierce_count <= 0:
			queue_free()
	else:
		queue_free()

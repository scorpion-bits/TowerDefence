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
		_apply_pedra_impact(enemy)
	elif effect_type == "instakill":
		var is_boss = enemy.scale.x > 1.2
		if not is_boss and enemy.has_node("HealthComponent"):
			enemy.get_node("HealthComponent").take_damage(99999)
	elif effect_type == "ice_aoe":
		_apply_gelo_impact(enemy)
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
		if enemy.has_method("apply_status_slow"):
			enemy.apply_status_slow("esqueleto_maldicao", 0.85, 3.0)
	elif effect_type == "pedra_estilhaco":
		_apply_pedra_impact(enemy)
		_pedra_splash_damage(enemy, 50.0, 0.5, false)
	elif effect_type == "pedra_bombardeio":
		_apply_pedra_impact(enemy)
		_pedra_splash_damage(enemy, 90.0, 0.8, true)

# --- GOLEM DE PEDRA (CANHÃO) ---
# Compartilhado entre "slow_hit" (base) e as variantes de explosão (pedra_estilhaco/
# pedra_bombardeio), para que a lentidão de impacto e os efeitos de controle continuem
# ativos independente de qual ramo de skill do Pedra o jogador escolheu.

func _apply_pedra_impact(enemy: Node2D) -> void:
	if enemy.has_method("apply_status_slow"):
		enemy.apply_status_slow("pedra_slow", effect_value, 3.0)

	if GameManager.has_skill("pedra_onda_de_choque"):
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and e != enemy and e.global_position.distance_to(enemy.global_position) < 40.0:
				if e.has_method("apply_status_slow"):
					e.apply_status_slow("pedra_slow", effect_value, 3.0)

	if GameManager.has_skill("pedra_atordoamento") and randf() <= 0.15:
		if enemy.has_method("apply_stun"):
			enemy.apply_stun(1.0)

func _pedra_splash_damage(center_enemy: Node2D, radius: float, dmg_pct: float, also_slow: bool) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e != center_enemy and e.global_position.distance_to(center_enemy.global_position) < radius:
			if e.has_node("HealthComponent"):
				e.get_node("HealthComponent").take_damage(int(hitbox_component.damage * dmg_pct))
			if also_slow and e.has_method("apply_status_slow"):
				e.apply_status_slow("pedra_slow", effect_value, 3.0)

# --- GOLEM DE GELO (LENTIDÃO) ---

func _apply_gelo_impact(enemy: Node2D) -> void:
	var duration = 4.0 if GameManager.has_skill("gelo_duracao") else 2.5

	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.global_position.distance_to(enemy.global_position) < 80.0:
			if e.has_method("apply_status_slow"):
				e.apply_status_slow("ice_aoe", effect_value, duration)

	if GameManager.has_skill("gelo_congelamento") and randf() <= 0.12:
		if enemy.has_method("apply_stun"):
			enemy.apply_stun(1.5)

	if GameManager.has_skill("gelo_zona_persistente"):
		_spawn_ice_zone(enemy.global_position, duration)

func _spawn_ice_zone(pos: Vector2, slow_duration: float) -> void:
	var zone_radius = 120.0 if GameManager.has_skill("gelo_nevasca") else 60.0
	var zone_lifetime = 6.0 if GameManager.has_skill("gelo_nevasca") else 3.0

	var zone = Area2D.new()
	zone.global_position = pos

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = zone_radius
	col.shape = shape
	zone.add_child(col)

	var spr = Sprite2D.new()
	spr.texture = preload("res://icon.svg")
	spr.scale = Vector2(zone_radius / 40.0, zone_radius / 40.0)
	spr.modulate = Color(0.4, 0.8, 1.0, 0.35)
	zone.add_child(spr)

	get_tree().current_scene.add_child(zone)

	zone.area_entered.connect(func(area):
		if area is HurtboxComponent and area.owner and area.owner.is_in_group("enemies"):
			if area.owner.has_method("apply_status_slow"):
				area.owner.apply_status_slow("ice_aoe", effect_value, slow_duration)
	)

	var timer = get_tree().create_timer(zone_lifetime)
	timer.timeout.connect(func(): if is_instance_valid(zone): zone.queue_free())

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

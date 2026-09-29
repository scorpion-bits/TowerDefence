extends Node2D

@export var data: TowerData
@export var projectile_scene: PackedScene

@onready var targeting_component: TargetingComponent = $TargetingComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_timer: Timer = $AttackTimer

var show_range: bool = false
var valid_path_points: PackedVector2Array = []

func _ready() -> void:
	add_to_group("towers")
	if data:
		if sprite: sprite.modulate = data.color
		attack_timer.timeout.connect(_on_attack_timer_timeout)
		_update_stats()
		
		if data.effect_type == "ice_aoe":
			targeting_component.enemy_entered.connect(_on_enemy_entered_aura)
			targeting_component.enemy_exited.connect(_on_enemy_exited_aura)
			
	GameManager.tower_selected.connect(_on_global_tower_selected)
	GameManager.tower_deselected.connect(func(): set_show_range(false))
	GameManager.skill_unlocked.connect(_on_skill_unlocked)
	
	call_deferred("_find_valid_path_points")

func _on_skill_unlocked(_skill_id: String) -> void:
	# Update stats whenever a new skill is unlocked
	_update_stats()

func get_current_damage() -> int:
	if not data: return 0
	return int(data.attack_damage + GameManager.get_tower_bonus(data.tower_name, "damage"))

func get_current_range() -> float:
	if not data: return 0.0
	return data.attack_range + GameManager.get_tower_bonus(data.tower_name, "range")

func get_current_cooldown() -> float:
	if not data: return 0.1
	var cd = data.attack_cooldown - GameManager.get_tower_bonus(data.tower_name, "fire_rate")
	return max(0.1, cd)

func get_current_effect_value() -> float:
	if not data: return 0.0
	return data.effect_value + GameManager.get_tower_bonus(data.tower_name, "effect_value")

func _find_valid_path_points() -> void:
	valid_path_points.clear()
	var path_node = get_tree().current_scene.get_node_or_null("Path2D")
	if not path_node or not path_node.curve: return
	
	var curve = path_node.curve
	var length = curve.get_baked_length()
	var step = 15.0
	for d in range(0, int(length), int(step)):
		var pt = path_node.to_global(curve.sample_baked(d))
		if pt.distance_to(global_position) <= get_current_range():
			valid_path_points.append(pt)

func _on_global_tower_selected(tower: Node2D) -> void:
	set_show_range(tower == self)

func set_show_range(is_visible: bool) -> void:
	show_range = is_visible
	queue_redraw()

func _draw() -> void:
	if show_range and data:
		draw_circle(Vector2.ZERO, get_current_range(), Color(0.2, 0.8, 1.0, 0.2))

func _update_stats() -> void:
	if targeting_component:
		var col_shape = targeting_component.get_node("CollisionShape2D")
		if not col_shape.shape.resource_local_to_scene:
			col_shape.shape = col_shape.shape.duplicate()
			col_shape.shape.resource_local_to_scene = true
			
		if col_shape.shape is CircleShape2D: 
			col_shape.shape.radius = get_current_range()
			
	attack_timer.wait_time = get_current_cooldown()
	if attack_timer.is_stopped():
		attack_timer.start()
		
	queue_redraw()
	_find_valid_path_points()

var attacks_count = 0

func _on_attack_timer_timeout() -> void:
	if not data or not projectile_scene or not targeting_component: return
	
	if data.effect_type == "ice_aoe":
		return 
		
	if data.effect_type == "poison_path" or data.effect_type == "fire_path":
		_spawn_trap_randomly()
		return
		
	if data.tower_name == "Esqueleto (Básico)" and GameManager.has_skill("esqueleto_chuva"):
		attacks_count += 1
		if attacks_count >= 5:
			attacks_count = 0
			_fire_spiral()
			return
			
	var prioritize = (data.tower_name == "Esqueleto (Básico)" and GameManager.has_skill("esqueleto_mirada_alta"))
	var target = targeting_component.get_closest_target(global_position, prioritize)
	if target: _shoot(target)

func _fire_spiral() -> void:
	var count = randi_range(4, 6)
	for i in range(count):
		var angle = (float(i) / count) * TAU
		var dir = Vector2.RIGHT.rotated(angle)
		var proj = projectile_scene.instantiate()
		get_tree().current_scene.add_child(proj) 
		proj.global_position = global_position
		
		# Projéteis em espiral não seguem um alvo específico, então passamos o alvo nulo 
		# mas precisamos alterar o projétil para lidar com isso ou dar um alvo falso.
		# O ideal é achar o inimigo mais próximo naquela direção, ou disparar em linha reta.
		# Vamos pegar inimigos aleatórios para simular a espiral!
		var enemies = targeting_component.enemies_in_range.filter(func(e): return is_instance_valid(e))
		var tgt = enemies[i % enemies.size()] if enemies.size() > 0 else null
		if tgt:
			proj.setup(tgt, get_current_damage(), data.projectile_speed, data.color, data.effect_type, get_current_effect_value())
		else:
			proj.queue_free()

func _fire_projectile(target: Node2D) -> void:
	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj) 
	proj.global_position = global_position
	
	var eff = data.effect_type
	var eff_val = get_current_effect_value()
	
	if data.tower_name == "Esqueleto (Básico)":
		if GameManager.has_skill("esqueleto_estilhaco"): eff = "esqueleto_estilhaco"
		if GameManager.has_skill("esqueleto_maldicao"): eff = "esqueleto_maldicao"
		if GameManager.has_skill("esqueleto_perfurante"): eff = "esqueleto_perfurante"
		
	proj.setup(target, get_current_damage(), data.projectile_speed, data.color, eff, eff_val)

func _shoot(target: Node2D) -> void:
	if data.effect_type == "buff":
		_apply_buff_to_towers()
		return
		
	_fire_projectile(target)
	
	if data.tower_name == "Esqueleto (Básico)" and GameManager.has_skill("esqueleto_arco_duplo"):
		var enemies = targeting_component.enemies_in_range.filter(func(e): return is_instance_valid(e))
		if enemies.size() > 1:
			var second = enemies[0] if enemies[0] != target else enemies[1]
			_fire_projectile(second)
		else:
			_fire_projectile(target)


func _on_enemy_entered_aura(enemy: Node2D) -> void:
	if enemy.has_method("add_slow"):
		enemy.add_slow(get_current_effect_value())

func _on_enemy_exited_aura(enemy: Node2D) -> void:
	if enemy.has_method("remove_slow"):
		enemy.remove_slow()

func _spawn_trap_randomly() -> void:
	if valid_path_points.is_empty():
		return
		
	var random_pt = valid_path_points[randi() % valid_path_points.size()]
	
	var trap = Area2D.new()
	trap.global_position = random_pt
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15.0
	col.shape = shape
	trap.add_child(col)
	
	var spr = Sprite2D.new()
	spr.texture = preload("res://icon.svg")
	spr.scale = Vector2(0.2, 0.2)
	spr.modulate = data.color
	spr.modulate.a = 0.8
	trap.add_child(spr)
	
	var e_type = data.effect_type
	trap.area_entered.connect(func(area): _on_trap_area_entered(area, trap, e_type))
	
	get_tree().current_scene.add_child(trap)
	
	if e_type == "fire_path":
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(func(): if is_instance_valid(trap): trap.queue_free())
	elif e_type == "poison_path":
		var timer = get_tree().create_timer(10.0)
		timer.timeout.connect(func(): if is_instance_valid(trap): trap.queue_free())

func _on_trap_area_entered(area: Area2D, trap: Area2D, e_type: String) -> void:
	if area is HurtboxComponent and area.owner and area.owner.is_in_group("enemies"):
		if e_type == "poison_path":
			if area.owner.has_method("apply_poison"):
				area.owner.apply_poison(get_current_damage(), 3.0)
			if is_instance_valid(trap): trap.queue_free()
		elif e_type == "fire_path":
			if area.owner.has_method("apply_burn"):
				area.owner.apply_burn(get_current_damage(), 3.0)

func _on_texture_button_pressed() -> void:
	GameManager.tower_selected.emit(self)

func _apply_buff_to_towers() -> void:
	var towers = get_tree().get_nodes_in_group("towers")
	for t in towers:
		if t != self and is_instance_valid(t):
			if t.global_position.distance_to(global_position) <= get_current_range():
				if t.has_method("get_current_cooldown"):
					if t.attack_timer:
						t.attack_timer.start(t.get_current_cooldown() / get_current_effect_value())

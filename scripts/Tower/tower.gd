extends Node2D

@export var data: TowerData
@export var projectile_scene: PackedScene

@onready var targeting_component: TargetingComponent = $TargetingComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_timer: Timer = $AttackTimer

var damage_level: int = 1
var fire_rate_level: int = 1
var range_level: int = 1
var base_upgrade_cost: int = 25
var show_range: bool = false
var total_upgrades: int = 0
var max_total_upgrades: int = 5

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
	
	# Delay path point calculation slightly to ensure tower position is final
	call_deferred("_find_valid_path_points")

func _find_valid_path_points() -> void:
	valid_path_points.clear()
	var path_node = get_tree().current_scene.get_node_or_null("Path2D")
	if not path_node or not path_node.curve: return
	
	var curve = path_node.curve
	var length = curve.get_baked_length()
	var step = 15.0
	for d in range(0, int(length), int(step)):
		var pt = path_node.to_global(curve.sample_baked(d))
		if pt.distance_to(global_position) <= data.attack_range:
			valid_path_points.append(pt)

func _on_global_tower_selected(tower: Node2D) -> void:
	set_show_range(tower == self)

func set_show_range(is_visible: bool) -> void:
	show_range = is_visible
	queue_redraw()

func _draw() -> void:
	if show_range and data:
		draw_circle(Vector2.ZERO, data.attack_range, Color(0.2, 0.8, 1.0, 0.2))

func _update_stats() -> void:
	if targeting_component:
		var col_shape = targeting_component.get_node("CollisionShape2D")
		if not col_shape.shape.resource_local_to_scene:
			col_shape.shape = col_shape.shape.duplicate()
			col_shape.shape.resource_local_to_scene = true
			
		if col_shape.shape is CircleShape2D: 
			col_shape.shape.radius = data.attack_range
			
	attack_timer.wait_time = data.attack_cooldown
	if attack_timer.is_stopped():
		attack_timer.start()
		
	queue_redraw()
	_find_valid_path_points()

func _on_attack_timer_timeout() -> void:
	if not data or not projectile_scene or not targeting_component: return
	
	if data.effect_type == "ice_aoe":
		return # Ice aura doesn't shoot
		
	if data.effect_type == "poison_path" or data.effect_type == "fire_path":
		_spawn_trap_randomly()
		return
		
	var target = targeting_component.get_closest_target(global_position)
	if target: _shoot(target)

func _shoot(target: Node2D) -> void:
	if data.effect_type == "buff":
		_apply_buff_to_towers()
		return
		
	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj) 
	proj.global_position = global_position
	proj.setup(target, data.attack_damage, data.projectile_speed, data.color, data.effect_type, data.effect_value)

func _on_enemy_entered_aura(enemy: Node2D) -> void:
	if enemy.has_method("add_slow"):
		enemy.add_slow(data.effect_value)

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
		# Fire paths disappear after 3 seconds
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(func(): if is_instance_valid(trap): trap.queue_free())
	# Poison path stays forever (accumulates) until hit

func _on_trap_area_entered(area: Area2D, trap: Area2D, e_type: String) -> void:
	if area is HurtboxComponent and area.owner and area.owner.is_in_group("enemies"):
		if e_type == "poison_path":
			if area.owner.has_method("apply_poison"):
				# Applying poison status
				area.owner.apply_poison(data.attack_damage, 3.0)
			if is_instance_valid(trap): trap.queue_free()
		elif e_type == "fire_path":
			if area.owner.has_method("apply_burn"):
				area.owner.apply_burn(data.attack_damage, 3.0)

func _on_texture_button_pressed() -> void:
	GameManager.tower_selected.emit(self)

func can_upgrade() -> bool:
	return total_upgrades < max_total_upgrades

func upgrade_damage() -> void:
	if not can_upgrade(): return
	var cost = get_damage_cost()
	if GameManager.spend_xp(cost):
		damage_level += 1
		total_upgrades += 1
		data.attack_damage += max(1, int(data.attack_damage * 0.5))

func upgrade_fire_rate() -> void:
	if not can_upgrade(): return
	var cost = get_fire_rate_cost()
	if GameManager.spend_xp(cost):
		fire_rate_level += 1
		total_upgrades += 1
		data.attack_cooldown *= 0.8
		_update_stats()

func upgrade_range() -> void:
	if not can_upgrade(): return
	var cost = get_range_cost()
	if GameManager.spend_xp(cost):
		range_level += 1
		total_upgrades += 1
		data.attack_range += 30.0 
		_update_stats()

func get_damage_cost() -> int: return base_upgrade_cost * (damage_level)
func get_fire_rate_cost() -> int: return base_upgrade_cost * (fire_rate_level)
func get_range_cost() -> int: return base_upgrade_cost * (range_level)

func _apply_buff_to_towers() -> void:
	var towers = get_tree().get_nodes_in_group("towers")
	for t in towers:
		if t != self and is_instance_valid(t):
			if t.global_position.distance_to(global_position) <= data.attack_range:
				if "data" in t and is_instance_valid(t.data):
					if t.attack_timer:
						t.attack_timer.start(t.data.attack_cooldown / data.effect_value)

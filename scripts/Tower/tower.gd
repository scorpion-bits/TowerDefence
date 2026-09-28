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

func _ready() -> void:
	if data:
		if sprite: sprite.modulate = data.color
		attack_timer.timeout.connect(_on_attack_timer_timeout)
		_update_stats()
		
	GameManager.tower_selected.connect(_on_global_tower_selected)
	GameManager.tower_deselected.connect(func(): set_show_range(false))

func _on_global_tower_selected(tower: Node2D) -> void:
	set_show_range(tower == self)

func set_show_range(visible: bool) -> void:
	show_range = visible
	queue_redraw()

func _draw() -> void:
	if show_range and data:
		draw_circle(Vector2.ZERO, data.attack_range, Color(0.2, 0.8, 1.0, 0.2))

func _update_stats() -> void:
	if targeting_component:
		var col_shape = targeting_component.get_node("CollisionShape2D")
		# Garante que a área de colisão (física) não seja compartilhada entre todas as torres
		if not col_shape.shape.resource_local_to_scene:
			col_shape.shape = col_shape.shape.duplicate()
			col_shape.shape.resource_local_to_scene = true
			
		if col_shape.shape is CircleShape2D: 
			col_shape.shape.radius = data.attack_range
			
	attack_timer.wait_time = data.attack_cooldown
	if attack_timer.is_stopped():
		attack_timer.start()
		
	queue_redraw()

func _on_attack_timer_timeout() -> void:
	if not data or not projectile_scene or not targeting_component: return
	
	var target = targeting_component.get_closest_target(global_position)
	if target: _shoot(target)

func _shoot(target: Node2D) -> void:
	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj) 
	proj.global_position = global_position
	proj.setup(target, data.attack_damage, data.projectile_speed, data.color)

func _on_texture_button_pressed() -> void:
	GameManager.tower_selected.emit(self)

# --- SISTEMA DE UPGRADES ---

func can_upgrade() -> bool:
	return total_upgrades < max_total_upgrades

func upgrade_damage() -> void:
	if not can_upgrade(): return
	var cost = get_damage_cost()
	if GameManager.spend_gold(cost):
		damage_level += 1
		total_upgrades += 1
		# Balanceamento: Aumenta o dano em 50%, ou no mínimo 1 (bom pra metralhadora que tem dano 1)
		data.attack_damage += max(1, int(data.attack_damage * 0.5))

func upgrade_fire_rate() -> void:
	if not can_upgrade(): return
	var cost = get_fire_rate_cost()
	if GameManager.spend_gold(cost):
		fire_rate_level += 1
		total_upgrades += 1
		data.attack_cooldown *= 0.8
		_update_stats()

func upgrade_range() -> void:
	if not can_upgrade(): return
	var cost = get_range_cost()
	if GameManager.spend_gold(cost):
		range_level += 1
		total_upgrades += 1
		data.attack_range += 30.0 
		_update_stats()

func get_damage_cost() -> int: return base_upgrade_cost * (damage_level)
func get_fire_rate_cost() -> int: return base_upgrade_cost * (fire_rate_level)
func get_range_cost() -> int: return base_upgrade_cost * (range_level)

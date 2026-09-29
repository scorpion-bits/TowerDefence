import os

content = '''extends Node

@export var enemy_scene: PackedScene
@export var path_to_spawn_on: Path2D
@export var base_enemy_data: EnemyData

var current_wave: int = 0
var enemies_to_spawn_this_wave: int = 0
var enemies_alive: int = 0
var is_wave_active: bool = false
var auto_start: bool = false

var spawn_timer: Timer

var enemy_types: Array[EnemyData] = []

func _ready() -> void:
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	GameManager.start_wave_requested.connect(start_next_wave)
	GameManager.auto_start_toggled.connect(_on_auto_start_toggled)
	
	_load_enemy_data()

func _load_enemy_data() -> void:
	var path = "res://resources/enemies/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				enemy_types.append(load(path + file_name) as EnemyData)
			file_name = dir.get_next()
			
	if enemy_types.size() == 0 and base_enemy_data:
		enemy_types.append(base_enemy_data)

func start_next_wave() -> void:
	if is_wave_active: return
	
	current_wave += 1
	is_wave_active = true
	enemies_to_spawn_this_wave = 5 + (current_wave * 2)
	
	# Boss wave logic
	if current_wave % 10 == 0:
		enemies_to_spawn_this_wave += 1
		
	GameManager.wave_updated.emit(current_wave)
	
	spawn_timer.wait_time = max(0.5, 2.0 - (current_wave * 0.1))
	spawn_timer.start()

func _on_auto_start_toggled(enabled: bool) -> void:
	auto_start = enabled

func _on_spawn_timer_timeout() -> void:
	if enemies_to_spawn_this_wave > 0:
		_spawn_enemy()
		enemies_to_spawn_this_wave -= 1
		enemies_alive += 1
	else:
		spawn_timer.stop()

func _spawn_enemy() -> void:
	if not enemy_scene or not path_to_spawn_on or enemy_types.size() == 0: return
	
	var new_enemy = enemy_scene.instantiate()
	
	var tex_index = (current_wave - 1) % enemy_types.size()
	var base_data = enemy_types[tex_index]
	
	var modified_data = base_data.duplicate()
	var is_boss = (current_wave % 10 == 0) and enemies_to_spawn_this_wave == 0 
	
	if is_boss:
		modified_data.max_health *= 10
		modified_data.reward *= 5
		modified_data.color = Color.PURPLE
		modified_data.speed *= 0.4
		new_enemy.scale = Vector2(2.5, 2.5)
	else:
		var scaling_factor = 1.0 + (current_wave * 0.1)
		modified_data.max_health = int(modified_data.max_health * scaling_factor)
		modified_data.reward += int(current_wave / 2.0)
			
	new_enemy.data = modified_data
	new_enemy.scale *= 1.5
	
	var hp = new_enemy.get_node("HealthComponent")
	if hp: hp.died.connect(_on_enemy_destroyed)
	
	path_to_spawn_on.add_child(new_enemy)
	new_enemy.tree_exited.connect(_on_enemy_destroyed)

func _on_enemy_destroyed() -> void:
	enemies_alive -= 1
	if enemies_alive <= 0 and enemies_to_spawn_this_wave <= 0:
		_end_wave()

func _end_wave() -> void:
	is_wave_active = false
	if current_wave == 100:
		GameManager.victory.emit()
	elif auto_start:
		start_next_wave()
'''

with open('scripts/Level/wave_manager.gd', 'w', encoding='utf-8') as f:
    f.write(content)

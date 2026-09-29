import os
import re

with open('scripts/Level/wave_manager.gd', 'r', encoding='utf-8') as f:
    content = f.read()

texture_logic = '''
var enemy_textures: Array[Texture2D] = []
var boss_texture: Texture2D

func _ready() -> void:
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	GameManager.start_wave_requested.connect(start_next_wave)
	GameManager.auto_start_toggled.connect(_on_auto_start_toggled)
	
	_load_enemy_textures()

func _load_enemy_textures() -> void:
	var path = "res://assets/Enemies assets/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".png"):
				if "Voidbutterfly" in file_name:
					boss_texture = load(path + file_name) as Texture2D
				else:
					enemy_textures.append(load(path + file_name) as Texture2D)
			file_name = dir.get_next()
'''

content = re.sub(r'func _ready\(\) -> void:.*?_on_auto_start_toggled\)', texture_logic.strip(), content, flags=re.DOTALL)

old_spawn = '''func _spawn_enemy() -> void:
	if not enemy_scene or not path_to_spawn_on or not base_enemy_data: return
	
	var new_enemy = enemy_scene.instantiate()
	
	# Fazemos uma cópia dos dados base para poder alterar sem afetar os outros
	var modified_data = base_enemy_data.duplicate()
	
	# Lógica do Boss (Onda múltipla de 10, e sendo o último inimigo daquela onda a nascer)
	var is_boss = (current_wave % 10 == 0) and enemies_to_spawn_this_wave == 0 
	
	if is_boss:
		modified_data.max_health *= 10
		modified_data.reward *= 5
		modified_data.color = Color.PURPLE
		modified_data.speed *= 0.4 # Muito mais lento!
		new_enemy.scale = Vector2(1.5, 1.5) # Fica grandão
	else:
		# Escalonamento normal de vida e dinheiro (suave)
		var scaling_factor = 1.0 + (current_wave * 0.1) # +10% de vida por onda
		modified_data.max_health = int(modified_data.max_health * scaling_factor)
		modified_data.reward += int(current_wave / 2.0)
		
	new_enemy.data = modified_data
	
	# Quando o inimigo morrer, vamos rastrear
	var hp = new_enemy.get_node("HealthComponent")
	if hp: hp.died.connect(_on_enemy_died)
	
	path_to_spawn_on.add_child(new_enemy)'''

new_spawn = '''func _spawn_enemy() -> void:
	if not enemy_scene or not path_to_spawn_on or not base_enemy_data: return
	
	var new_enemy = enemy_scene.instantiate()
	var modified_data = base_enemy_data.duplicate()
	var is_boss = (current_wave % 10 == 0) and enemies_to_spawn_this_wave == 0 
	
	if is_boss:
		modified_data.max_health *= 10
		modified_data.reward *= 5
		modified_data.color = Color.PURPLE
		modified_data.speed *= 0.4
		new_enemy.scale = Vector2(2.5, 2.5)
		if boss_texture: modified_data.texture = boss_texture
	else:
		var scaling_factor = 1.0 + (current_wave * 0.1)
		modified_data.max_health = int(modified_data.max_health * scaling_factor)
		modified_data.reward += int(current_wave / 2.0)
		if enemy_textures.size() > 0:
			var tex_index = (current_wave - 1) % enemy_textures.size()
			modified_data.texture = enemy_textures[tex_index]
			
	new_enemy.data = modified_data
	new_enemy.scale *= 1.5 # The original placeholder was small, let's make these assets look good
	
	var hp = new_enemy.get_node("HealthComponent")
	if hp: hp.died.connect(_on_enemy_died)
	
	path_to_spawn_on.add_child(new_enemy)'''

content = re.sub(r'func _spawn_enemy\(\) -> void:.*?path_to_spawn_on\.add_child\(new_enemy\)', new_spawn, content, flags=re.DOTALL)

with open('scripts/Level/wave_manager.gd', 'w', encoding='utf-8') as f:
    f.write(content)


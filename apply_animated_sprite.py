import os
import re

# 1. Update EnemyData
with open('scripts/resources/enemy_data.gd', 'w', encoding='utf-8') as f:
    f.write('''class_name EnemyData
extends Resource

@export var enemy_name: String = "Enemy"
@export var speed: float = 100.0
@export var max_health: int = 10
@export var reward: int = 5
@export var damage_to_player: int = 1
@export var color: Color = Color.WHITE
@export var sprite_frames: SpriteFrames
''')

# 2. Update enemy.tscn to use AnimatedSprite2D instead of Sprite2D
with open('scenes/enemy.tscn', 'r', encoding='utf-8') as f:
    tscn = f.read()

# Replace Sprite2D node with AnimatedSprite2D
tscn = re.sub(r'\[node name="Sprite2D" type="Sprite2D".*?\]\n.*?texture = ExtResource\("3_nenq2"\).*?(?=\[node)', 
              '[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="." unique_id=1683765151]\n\n', 
              tscn, flags=re.DOTALL)

with open('scenes/enemy.tscn', 'w', encoding='utf-8') as f:
    f.write(tscn)

# 3. Update enemy.gd to use AnimatedSprite2D and sprite_frames
with open('scripts/Enemy/enemy.gd', 'w', encoding='utf-8') as f:
    f.write('''extends PathFollow2D

@export var data: EnemyData

@onready var anim_sprite: AnimatedSprite2D = 
@onready var health_component: HealthComponent = 

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
''')

# 4. Update wave_manager.gd to load .tres instead of .png
with open('scripts/Level/wave_manager.gd', 'r', encoding='utf-8') as f:
    wave = f.read()

wave_logic = '''
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
'''

wave = re.sub(r'var enemy_textures: Array\[Texture2D\] = \[\]\nvar boss_texture: Texture2D\n\nfunc _ready\(\) -> void:.*?_load_enemy_textures\(\)\n\nfunc _load_enemy_textures\(\) -> void:.*?file_name = dir.get_next\(\)', wave_logic.strip(), wave, flags=re.DOTALL)

spawn_logic = '''func _spawn_enemy() -> void:
	if not enemy_scene or not path_to_spawn_on or enemy_types.size() == 0: return
	
	var new_enemy = enemy_scene.instantiate()
	
	# Pick an enemy type based on wave, or randomly
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
	if hp: hp.died.connect(_on_enemy_died)
	
	path_to_spawn_on.add_child(new_enemy)'''

wave = re.sub(r'func _spawn_enemy\(\) -> void:.*?path_to_spawn_on\.add_child\(new_enemy\)', spawn_logic, wave, flags=re.DOTALL)

with open('scripts/Level/wave_manager.gd', 'w', encoding='utf-8') as f:
    f.write(wave)

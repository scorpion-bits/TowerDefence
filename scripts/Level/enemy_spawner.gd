extends Node

@export var enemy_scene: PackedScene
@export var path_to_spawn_on: Path2D
@export var spawn_interval: float = 2.0

var spawn_timer: Timer

func _ready() -> void:
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn)
	spawn_timer.start()

func _on_spawn() -> void:
	if not enemy_scene or not path_to_spawn_on: return
	
	var new_enemy = enemy_scene.instantiate()
	path_to_spawn_on.add_child(new_enemy)

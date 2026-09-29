class_name TargetingComponent
extends Area2D

signal enemy_entered(enemy: Node2D)
signal enemy_exited(enemy: Node2D)

var enemies_in_range: Array[Node2D] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if area.owner and area.owner.is_in_group("enemies"):
		if not enemies_in_range.has(area.owner):
			enemies_in_range.append(area.owner)
			enemy_entered.emit(area.owner)

func _on_area_exited(area: Area2D) -> void:
	if area.owner and enemies_in_range.has(area.owner):
		enemies_in_range.erase(area.owner)
		enemy_exited.emit(area.owner)

func get_closest_target(_global_pos: Vector2) -> Node2D:
	if enemies_in_range.is_empty(): return null
		
	var best_enemy: Node2D = null
	var highest_progress: float = -1.0
	
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			if "progress" in enemy:
				if enemy.progress > highest_progress:
					highest_progress = enemy.progress
					best_enemy = enemy
				
	return best_enemy

class_name HealthComponent
extends Node

signal died
signal health_changed(current_health: int, max_health: int)

@export var max_health: int = 10
var current_health: int

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	current_health -= amount
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()

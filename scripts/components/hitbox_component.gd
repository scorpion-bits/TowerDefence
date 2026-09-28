class_name HitboxComponent
extends Area2D

signal dealt_damage(target: HurtboxComponent)

@export var damage: int = 5

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		area.take_damage(damage)
		dealt_damage.emit(area)

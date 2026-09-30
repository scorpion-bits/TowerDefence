class_name HurtboxComponent
extends Area2D

@export var health_component: HealthComponent

func take_damage(amount: int) -> void:
	if health_component:
		if owner and owner.has_method("get_physical_damage_multiplier"):
			amount = int(amount * owner.get_physical_damage_multiplier())
		health_component.take_damage(amount)

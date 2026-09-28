extends Node2D

@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var sprite: Sprite2D = $Sprite2D

var target: Node2D
var speed: float = 300.0

func _ready() -> void:
	if hitbox_component:
		hitbox_component.dealt_damage.connect(_on_dealt_damage)

func setup(_target: Node2D, _damage: int, _speed: float, _color: Color) -> void:
	target = _target
	speed = _speed
	if hitbox_component: hitbox_component.damage = _damage
	if sprite: sprite.modulate = _color

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
		
	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta
	rotation = direction.angle()

func _on_dealt_damage(_hurtbox: HurtboxComponent) -> void:
	queue_free()

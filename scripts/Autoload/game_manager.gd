extends Node

signal gold_changed(new_amount: int)
signal lives_changed(new_amount: int)
signal game_over
signal drag_started(tower_data: TowerData)
signal start_wave_requested
signal auto_start_toggled(enabled: bool)
signal wave_updated(wave_number: int)
signal tower_selected(tower: Node2D)
signal tower_deselected

var gold: int = 150
var lives: int = 20

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

func take_damage(amount: int) -> void:
	lives -= amount
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()
		print("game over")

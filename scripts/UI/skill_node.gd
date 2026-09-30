class_name SkillNode
extends TextureButton

@export var skill_id: String = ""

var is_unlocked: bool = false
var can_unlock: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(48, 48)
	pressed.connect(_on_pressed)
	GameManager.skill_unlocked.connect(_on_any_skill_unlocked)
	GameManager.skill_points_changed.connect(_on_points_changed)
	call_deferred("_update_state")

func _on_any_skill_unlocked(_id: String) -> void:
	_update_state()

func _on_points_changed(_pts: int) -> void:
	_update_state()

func _update_state() -> void:
	if not GameManager.skill_tree_data.has(skill_id):
		tooltip_text = "?"
		return
		
	var data = GameManager.skill_tree_data[skill_id]
	is_unlocked = GameManager.unlocked_skills.has(skill_id)
	
	var reqs_met = GameManager.can_unlock_skill(skill_id)
	var cost = GameManager.get_skill_cost(skill_id)
	
	can_unlock = not is_unlocked and reqs_met and GameManager.skill_points >= cost
	
	# Update visual style
	if is_unlocked:
		modulate = Color.WHITE # Gold for unlocked (sprite should have color)
	elif reqs_met:
		if can_unlock:
			modulate = Color(0.8, 1.0, 0.8) # Green for available to buy
		else:
			modulate = Color(0.5, 0.5, 0.5)
	else:
		modulate = Color(0.15, 0.15, 0.15) # Dark grey for locked

	# Set tooltip
	var display_cost = cost if not is_unlocked else 0
	var desc = GameManager.get_skill_description(skill_id)
	tooltip_text = "%s — %s\nCusto: %d SP" % [data.tower, desc, display_cost]
	
	# Update tree drawing
	var p = get_parent()
	while p != null:
		if p.name == "TreeContainer" and p.has_method("queue_redraw"):
			p.queue_redraw()
			break
		p = p.get_parent()

func _on_pressed() -> void:
	if can_unlock:
		GameManager.buy_skill(skill_id)

func has_reqs_met() -> bool:
	return GameManager.can_unlock_skill(skill_id) or is_unlocked

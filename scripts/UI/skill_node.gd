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
		text = "?"
		return
		
	var data = GameManager.skill_tree_data[skill_id]
	is_unlocked = GameManager.unlocked_skills.has(skill_id)
	
	# Check if requirements are met
	var reqs_met = true
	for req in data.requires:
		if not GameManager.unlocked_skills.has(req):
			reqs_met = false
			break
			
	can_unlock = not is_unlocked and reqs_met and GameManager.skill_points >= GameManager.get_next_skill_cost()
	
	# Update visual style
	if is_unlocked:
		modulate = Color.WHITE # Yellow/Gold for unlocked
	elif reqs_met:
		if can_unlock:
			modulate = Color(0.8, 1.0, 0.8) # Green for available to buy
		else:
			modulate = Color(0.5, 0.5, 0.5) # White for affordable but not enough points
	else:
		modulate = Color(0.15, 0.15, 0.15) # Dark grey for locked

	# Set tooltip
	var cost = GameManager.get_next_skill_cost() if not is_unlocked else 0
	tooltip_text = "Habilidade: %s\nTorre: %s\nAtributo: %s +%s\nCusto: %d SP" % [
		skill_id, data.tower, data.stat, str(data.value), cost
	]
	
	# Update tree drawing
	var parent = get_parent()
	if parent and parent.has_method("queue_redraw"):
		parent.queue_redraw()

func _on_pressed() -> void:
	if can_unlock:
		GameManager.buy_skill(skill_id)

func has_reqs_met() -> bool:
	if not GameManager.skill_tree_data.has(skill_id): return false
	var data = GameManager.skill_tree_data[skill_id]
	for req in data.requires:
		if not GameManager.unlocked_skills.has(req): return false
	return true

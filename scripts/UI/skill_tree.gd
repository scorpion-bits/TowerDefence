extends CanvasLayer

@onready var container: Control = $TreeContainer
@onready var points_label: Label = $TopPanel/PointsLabel
@onready var cost_label: Label = $TopPanel/CostLabel
@onready var close_btn: Button = $TopPanel/CloseButton

var dragging: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	close_btn.pressed.connect(_on_close)
	GameManager.skill_points_changed.connect(_update_labels)
	GameManager.skill_unlocked.connect(_on_skill_unlocked)
	_update_labels(GameManager.skill_points)
	
	# Associa a função de desenho ao container
	container.draw.connect(_on_container_draw)

func _update_labels(_pts: int = 0) -> void:
	points_label.text = "Skill Points: " + str(GameManager.skill_points)
	cost_label.text = "Custo da Próxima: " + str(GameManager.get_next_skill_cost())

func _on_skill_unlocked(_id: String) -> void:
	_update_labels()

func _on_close() -> void:
	hide()
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if not visible: return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				dragging = true
				last_mouse_pos = event.position
			else:
				dragging = false
				
	elif event is InputEventMouseMotion and dragging:
		container.position += (event.position - last_mouse_pos)
		last_mouse_pos = event.position

func _on_container_draw() -> void:
	# Encontra todos os nós de habilidade
	var nodes = {}
	for child in container.get_children():
		if child is SkillNode:
			nodes[child.skill_id] = child
			
	# Desenha as linhas baseadas nos requisitos
	for child in container.get_children():
		if child is SkillNode:
			var data = GameManager.skill_tree_data.get(child.skill_id)
			if data:
				for req_id in data.requires:
					if nodes.has(req_id):
						var req_node = nodes[req_id]
						var start_pos = child.position + child.size / 2.0
						var end_pos = req_node.position + req_node.size / 2.0
						
						var color = Color(0.3, 0.3, 0.3, 1.0) # Locked
						if GameManager.unlocked_skills.has(child.skill_id):
							color = Color(1.0, 0.8, 0.2, 1.0) # Gold / Unlocked
						elif child.has_reqs_met():
							color = Color(0.5, 1.0, 0.5, 0.5) # Available line
						
						container.draw_line(start_pos, end_pos, color, 4.0)


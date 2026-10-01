extends PathFollow2D

@export var data: EnemyData

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $HealthComponent

var speed_modifier: float = 1.0

var burn_stacks: Array[Dictionary] = []

var poison_stacks: Array[Dictionary] = []

var slow_sources: int = 0

func _ready() -> void:
	loop = false
	if data:
		health_component.max_health = data.max_health
		health_component.current_health = data.max_health
		
		if anim_sprite and data.sprite_frames:
			anim_sprite.sprite_frames = data.sprite_frames
			anim_sprite.play("default")
		elif anim_sprite:
			anim_sprite.modulate = data.color
			
	if health_component:
		health_component.died.connect(_on_died)

func _process(delta: float) -> void:
	if data:
		if stun_time_left > 0:
			stun_time_left -= delta
		else:
			var current_speed = data.speed * speed_modifier
			if is_panicked:
				panic_time_left -= delta
				if panic_time_left <= 0:
					is_panicked = false
				progress -= current_speed * delta # Move backwards
			else:
				progress += current_speed * delta

		if progress_ratio >= 1.0:
			_reach_end()
			
	if satelite_mark_time > 0:
		satelite_mark_time -= delta

	if burn_stacks.size() > 0:
		var bi = burn_stacks.size() - 1
		while bi >= 0:
			burn_stacks[bi].time -= delta
			burn_stacks[bi].tick_timer -= delta

			if burn_stacks[bi].tick_timer <= 0.0:
				burn_stacks[bi].tick_timer = 1.0
				health_component.take_damage(int(burn_stacks[bi].dmg))
				if GameManager.has_skill("fogo_inferno"):
					_spread_fire_to_nearby(burn_stacks[bi].dmg, burn_stacks[bi].time)
				if GameManager.has_skill("fogo_pavor") and randf() <= 0.05:
					apply_panic(2.0)

			if burn_stacks[bi].time <= 0.0:
				burn_stacks.remove_at(bi)
			bi -= 1


	if poison_stacks.size() > 0:
		var i = poison_stacks.size() - 1
		while i >= 0:
			poison_stacks[i].time -= delta
			poison_stacks[i].tick_timer -= delta
			
			if poison_stacks[i].tick_timer <= 0.0:
				poison_stacks[i].tick_timer = 1.0
				var dmg = _get_poison_tick_damage(poison_stacks[i].dmg)
				health_component.take_damage(int(dmg))
				
			if poison_stacks[i].time <= 0.0:
				poison_stacks.remove_at(i)
			i -= 1
			
		if poison_stacks.size() == 0 and has_meta("neuro_slow"):
			remove_meta("neuro_slow")
			
	var new_speed_modifier = 1.0
	var keys_to_remove = []
	for key in active_slows:
		active_slows[key].time -= delta
		if active_slows[key].time <= 0:
			keys_to_remove.append(key)
		else:
			new_speed_modifier *= active_slows[key].multiplier
			
	for key in keys_to_remove:
		active_slows.erase(key)
		
	if has_meta("neuro_slow"):
		new_speed_modifier *= 0.80
		
	speed_modifier = new_speed_modifier * aura_speed_modifier
	
	_update_visuals()

var active_slows: Dictionary = {}

func apply_status_slow(source_id: String, multiplier: float, duration: float) -> void:
	if active_slows.has(source_id):
		var current_mult = active_slows[source_id].multiplier
		active_slows[source_id].multiplier = min(current_mult, multiplier) # Mantém o mais forte (menor valor)
		active_slows[source_id].time = max(active_slows[source_id].time, duration)
	else:
		active_slows[source_id] = {"multiplier": multiplier, "time": duration}

var aura_slows: Dictionary = {}
var aura_speed_modifier: float = 1.0

func add_slow(amount: float) -> void:
	if not aura_slows.has(amount):
		aura_slows[amount] = 0
	aura_slows[amount] += 1
	_recalc_aura_speed()

func remove_slow(amount: float = 0.0) -> void:
	if amount != 0.0 and aura_slows.has(amount):
		aura_slows[amount] -= 1
		if aura_slows[amount] <= 0:
			aura_slows.erase(amount)
	_recalc_aura_speed()

func _recalc_aura_speed() -> void:
	aura_speed_modifier = 1.0
	for m in aura_slows.keys():
		aura_speed_modifier *= m

var is_panicked: bool = false
var panic_time_left: float = 0.0

var stun_time_left: float = 0.0

var laser_slow_time: float = 0.0
var satelite_mark_time: float = 0.0

func apply_laser_slow(amt: float, dur: float) -> void:
	apply_status_slow("laser", amt, dur)

func apply_satelite_mark(dur: float) -> void:
	satelite_mark_time = dur

func apply_panic(duration: float) -> void:
	is_panicked = true
	panic_time_left = max(panic_time_left, duration)

func apply_stun(duration: float) -> void:
	stun_time_left = max(stun_time_left, duration)

func apply_burn(dmg: int, duration: float) -> void:
	var max_stacks = 3 if GameManager.has_skill("fogo_conflagracao") else 1

	if burn_stacks.size() >= max_stacks:
		burn_stacks[0] = {"dmg": dmg, "time": duration, "tick_timer": 1.0}
		return

	burn_stacks.append({"dmg": dmg, "time": duration, "tick_timer": 1.0})

# Usado por fogo_inferno: espalha a queimadura para inimigos próximos que ainda não
# estão pegando fogo, a cada tique — cria um incêndio que se auto-sustenta enquanto
# tiver "combustível" por perto, sem reaplicar infinitamente no mesmo alvo já em chamas.
func _spread_fire_to_nearby(dmg: float, duration: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e != self and e.global_position.distance_to(global_position) < 50.0:
			if e.has_method("apply_burn") and e.burn_stacks.size() == 0:
				e.apply_burn(int(dmg), duration)

# A fórmula do dano por tique de veneno (base + bônus de planta_dano_1/planta_acido) é
# compartilhada entre o tique normal, a necrose (estouro ao atingir o limite de pilhas)
# e a epidemia (espalhar ao morrer), para não ficar reimplementada em 3 lugares.
func _get_poison_tick_damage(base_dmg: float) -> float:
	var dmg = base_dmg
	if GameManager.has_skill("planta_dano_1"): dmg *= 1.15
	if GameManager.has_skill("planta_acido"): dmg += health_component.max_health * 0.015
	return dmg

func apply_poison(dmg: float, duration: float) -> void:
	if GameManager.has_skill("planta_stack_1"):
		duration += 3.0

	var max_stacks = 3 if GameManager.has_skill("planta_stack_1") else 1

	if poison_stacks.size() >= max_stacks:
		if GameManager.has_skill("planta_necrose"):
			var total_dmg = 0.0
			for stack in poison_stacks:
				var ticks_left = max(1, int(stack.time))
				total_dmg += _get_poison_tick_damage(stack.dmg) * ticks_left
			poison_stacks.clear()
			if has_meta("neuro_slow"):
				remove_meta("neuro_slow")
			anim_sprite.modulate = Color(0.8, 1.0, 0.4) # Necrose visual flash
			health_component.take_damage(int(total_dmg))
			return
		else:
			poison_stacks[0] = {"dmg": dmg, "time": duration, "tick_timer": 1.0}
			return

	poison_stacks.append({"dmg": dmg, "time": duration, "tick_timer": 1.0})
	
	if GameManager.has_skill("planta_neuro") and not has_meta("neuro_slow"):
		set_meta("neuro_slow", true)

func _update_visuals() -> void:
	if not data or not anim_sprite: return
	if stun_time_left > 0:
		anim_sprite.modulate = Color(0.5, 0.5, 0.5) # Cinza (petrificado) para atordoado
	elif burn_stacks.size() > 0:
		anim_sprite.modulate = Color(1.0, 0.3, 0.0)
	elif poison_stacks.size() > 0:
		anim_sprite.modulate = Color(0.6, 0.2, 0.8) # Purple for poison
	elif active_slows.size() > 0 or aura_slows.size() > 0 or has_meta("neuro_slow"):
		anim_sprite.modulate = Color(0.3, 0.6, 1.0)
	elif is_panicked:
		anim_sprite.modulate = Color(1.0, 1.0, 0.3) # Yellowish for panic
	else:
		if not data.sprite_frames:
			anim_sprite.modulate = data.color
		else:
			anim_sprite.modulate = Color.WHITE

func _on_died() -> void:
	if poison_stacks.size() > 0 and GameManager.has_skill("planta_epidemia"):
		var total_dmg = 0.0
		for stack in poison_stacks:
			var ticks_left = max(1, int(stack.time))
			total_dmg += _get_poison_tick_damage(stack.dmg) * ticks_left
			
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and e != self and e.global_position.distance_to(global_position) < 80.0:
				if e.has_method("apply_poison"):
					e.apply_poison(total_dmg / 3.0, 3.0)

	if burn_stacks.size() > 0 and GameManager.has_skill("fogo_combustao"):
		var explosion_dmg = int(burn_stacks[0].dmg * 5)
		var enemies_c = get_tree().get_nodes_in_group("enemies")
		for e in enemies_c:
			if is_instance_valid(e) and e != self and e.global_position.distance_to(global_position) < 60.0:
				if e.has_node("HealthComponent"):
					e.get_node("HealthComponent").take_damage(explosion_dmg)

	var xp_reward = data.reward
	if has_meta("espantalho_xp_buff") and get_meta("espantalho_xp_buff"):
		xp_reward = int(xp_reward * 1.2) # +20%
	GameManager.add_xp(xp_reward)
	GameManager.roll_loot()
	queue_free()

func get_physical_damage_multiplier() -> float:
	var mult = 1.0
	if poison_stacks.size() > 0 and GameManager.has_skill("planta_neuro"):
		mult += 0.10
	if burn_stacks.size() > 0 and GameManager.has_skill("fogo_vulnerabilidade_1"):
		mult += 0.10
	if active_slows.has("ice_aoe") and GameManager.has_skill("gelo_fragil"):
		mult += 0.30
	if satelite_mark_time > 0:
		mult += 0.15
	return mult

func _reach_end() -> void:
	GameManager.take_damage(data.damage_to_player)
	queue_free()

extends Node2D

@export var data: TowerData
@export var projectile_scene: PackedScene

@onready var targeting_component: TargetingComponent = $TargetingComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_timer: Timer = $AttackTimer

var show_range: bool = false
var valid_path_points: PackedVector2Array = []

var frenzy_active: bool = false
var frenzy_timer: float = 0.0

var current_target: Node2D = null
var laser_targets: Array[Node2D] = []
var laser_chain_lines: Array = []
var laser_heat_timer: float = 0.0
var laser_heat_stacks: int = 0
var laser_lock_timer: float = 0.0

func _ready() -> void:
	add_to_group("towers")
	if data:
		if sprite: sprite.modulate = data.color
		attack_timer.timeout.connect(_on_attack_timer_timeout)
		_update_stats()
		
		if data.effect_type == "ice_aoe":
			targeting_component.enemy_entered.connect(_on_enemy_entered_aura)
			targeting_component.enemy_exited.connect(_on_enemy_exited_aura)
			
		if data.tower_name == "Espantalho (Buff)":
			targeting_component.enemy_entered.connect(_on_enemy_entered_espantalho)
			targeting_component.enemy_exited.connect(_on_enemy_exited_espantalho)
			
	GameManager.tower_selected.connect(_on_global_tower_selected)
	GameManager.tower_deselected.connect(func(): set_show_range(false))
	GameManager.skill_unlocked.connect(_on_skill_unlocked)
	GameManager.relocate_started.connect(_on_relocate_started_global)

	call_deferred("_find_valid_path_points")

func _on_relocate_started_global(tower: Node2D) -> void:
	# Para de atacar/spawnar armadilhas no local antigo assim que a torre é pega para mover.
	# É reativado por _update_stats(), chamado ao concluir ou cancelar a realocação (ver level.gd).
	if tower == self:
		attack_timer.stop()

func _get_valid_enemies(exclude: Array = []) -> Array:
	return targeting_component.enemies_in_range.filter(func(e): return is_instance_valid(e) and not exclude.has(e))

var spore_timer: float = 0.0

func _process(delta: float) -> void:
	if data and data.tower_name == "Espantalho (Buff)" and GameManager.has_skill("espantalho_frenesi"):
		frenzy_timer += delta
		if frenzy_timer >= 20.0:
			frenzy_active = true
			frenzy_timer = 0.0
			_update_towers_in_range_stats()
			get_tree().create_timer(5.0).timeout.connect(func():
				frenzy_active = false
				if is_instance_valid(self): _update_towers_in_range_stats()
			)
			
	if data and data.tower_name == "Planta Peçonhenta" and GameManager.has_skill("planta_esporos"):
		spore_timer += delta
		if spore_timer >= 15.0:
			spore_timer = 0.0
			_spawn_spore_cloud()
			
	if data and data.effect_type == "laser":
		laser_targets.clear()
		laser_chain_lines.clear()
		
		# Valida o target atual
		if is_instance_valid(current_target) and current_target.global_position.distance_to(global_position) <= get_current_range() and current_target.progress_ratio < 1.0:
			if laser_lock_timer > 0:
				laser_lock_timer -= delta
			else:
				if GameManager.has_skill("olho_calor_1"):
					laser_heat_timer += delta
					if laser_heat_timer >= 1.0 and laser_heat_stacks < 4:
						laser_heat_stacks += 1
						laser_heat_timer -= 1.0
				
				laser_targets.append(current_target)
				
				if GameManager.has_skill("olho_bifurcado"):
					var enemies = _get_valid_enemies([current_target])
					if enemies.size() > 0:
						laser_targets.append(enemies[0])

				if GameManager.has_skill("olho_cadeia"):
					var exclude = laser_targets.duplicate()
					for t in laser_targets:
						var ricochet = 2
						var enemies = _get_valid_enemies(exclude)
						for i in range(min(ricochet, enemies.size())):
							laser_chain_lines.append([t, enemies[i]])
							exclude.append(enemies[i])
		else:
			# Busca novo target
			var had_target = is_instance_valid(current_target)
			var new_target = targeting_component.get_closest_target(global_position)
			current_target = new_target
			laser_heat_stacks = 0
			laser_heat_timer = 0.0
			if new_target:
				# A trava de mira (delay) so se aplica quando a torre estava sem alvo nenhum.
				# Se estavamos trocando de um alvo que acabou de sair do alcance, o novo alvo
				# e engajado imediatamente para evitar que alvos aglomerados resetem a mira
				# indefinidamente e a torre fique sem atacar.
				if not had_target and not GameManager.has_skill("olho_instant"):
					laser_lock_timer = 0.3
				else:
					laser_lock_timer = 0.0
			else:
				laser_lock_timer = 0.0
				
		queue_redraw()

func _update_towers_in_range_stats() -> void:
	var towers = get_tree().get_nodes_in_group("towers")
	for t in towers:
		if t != self and is_instance_valid(t):
			if t.global_position.distance_to(global_position) <= get_current_range():
				t._update_stats()

func _on_enemy_entered_espantalho(enemy: Node2D) -> void:
	if GameManager.has_skill("espantalho_slow_1"):
		if enemy.has_method("add_slow"):
			enemy.add_slow(0.98) # 2% slow
	if GameManager.has_skill("espantalho_panico"):
		if randf() <= 0.05: # 5% chance
			if enemy.has_method("apply_panic"):
				enemy.apply_panic(2.0)
	if GameManager.has_skill("espantalho_xp_1"):
		enemy.set_meta("espantalho_xp_buff", true)

func _on_enemy_exited_espantalho(enemy: Node2D) -> void:
	if GameManager.has_skill("espantalho_slow_1"):
		if enemy.has_method("remove_slow"):
			enemy.remove_slow(0.98)
	if enemy.has_meta("espantalho_xp_buff"):
		enemy.set_meta("espantalho_xp_buff", false)

func _on_skill_unlocked(_skill_id: String) -> void:
	# Update stats whenever a new skill is unlocked
	_update_stats()

func get_espantalhos_in_range() -> Array:
	var espantalhos = []
	var towers = get_tree().get_nodes_in_group("towers")
	for t in towers:
		if t != self and is_instance_valid(t) and t.data and t.data.tower_name == "Espantalho (Buff)":
			# Usa o alcance base (sem multiplicador de buff) para evitar recursao infinita:
			# get_current_range() de t chamaria get_buff_multiplier() de t, que chamaria
			# get_espantalhos_in_range() de t novamente, e assim por diante entre torres mutuamente no alcance.
			if t.global_position.distance_to(global_position) <= t.get_base_range():
				espantalhos.append(t)
	return espantalhos

func get_buff_multiplier(buff_type: String) -> float:
	var espantalhos = get_espantalhos_in_range()
	if espantalhos.is_empty(): return 1.0
	
	var mult = 1.0
	var has_synergy = false
	var synergy_count = 0
	for esp in espantalhos:
		if GameManager.has_skill("espantalho_sinergia"):
			synergy_count += 1
	if synergy_count >= 2:
		has_synergy = true
		
	if buff_type == "damage" and GameManager.has_skill("espantalho_dano_1"):
		mult += 0.15
	if buff_type == "attack_speed" and GameManager.has_skill("espantalho_spd_1"):
		mult += 0.15
	if buff_type == "attack_speed" and GameManager.has_skill("espantalho_frenesi"):
		for esp in espantalhos:
			if "frenzy_active" in esp and esp.frenzy_active:
				mult += 1.0
				break
	if buff_type == "range" and GameManager.has_skill("espantalho_range_buff"):
		mult += 0.05
	if buff_type == "proj_speed" and GameManager.has_skill("espantalho_range_buff"):
		mult += 0.10
		
	if has_synergy and (buff_type == "damage" or buff_type == "attack_speed" or buff_type == "range" or buff_type == "proj_speed"):
		mult += 0.02
		
	return mult

func get_current_damage() -> int:
	if not data: return 0
	var base = data.attack_damage + GameManager.get_tower_bonus(data.tower_name, "damage")
	return int(base * get_buff_multiplier("damage"))

func get_base_range() -> float:
	if not data: return 0.0
	var r = data.attack_range + GameManager.get_tower_bonus(data.tower_name, "range")
	var r_pct = GameManager.get_tower_bonus(data.tower_name, "range_pct")
	if r_pct > 0.0:
		r *= (1.0 + r_pct)
	return r

func get_current_range() -> float:
	return get_base_range() * get_buff_multiplier("range")

func get_current_cooldown() -> float:
	if not data: return 0.1
	var cd = data.attack_cooldown - GameManager.get_tower_bonus(data.tower_name, "fire_rate")
	if data.tower_name == "Olho Flutuante (Laser)" and GameManager.has_skill("olho_spd_1"):
		cd = 0.10
	return max(0.05, cd / get_buff_multiplier("attack_speed"))

func get_crit_chance() -> float:
	if not data: return 0.0
	var chance = 0.0
	var espantalhos = get_espantalhos_in_range()
	if espantalhos.size() > 0 and GameManager.has_skill("espantalho_spd_1"):
		chance += 0.10
		var synergy_count = 0
		for esp in espantalhos:
			if GameManager.has_skill("espantalho_sinergia"): synergy_count += 1
		if synergy_count >= 2: chance += 0.02
	return chance

func get_proj_speed() -> float:
	if not data: return 300.0
	return data.projectile_speed * get_buff_multiplier("proj_speed")

func get_current_effect_value() -> float:
	if not data: return 0.0
	return data.effect_value + GameManager.get_tower_bonus(data.tower_name, "effect_value")


func _find_valid_path_points() -> void:
	valid_path_points.clear()
	var path_node = get_tree().current_scene.get_node_or_null("Path2D")
	if not path_node or not path_node.curve: return
	
	var curve = path_node.curve
	var length = curve.get_baked_length()
	var step = 15.0
	for d in range(0, int(length), int(step)):
		var pt = path_node.to_global(curve.sample_baked(d))
		if pt.distance_to(global_position) <= get_current_range():
			valid_path_points.append(pt)

func _on_global_tower_selected(tower: Node2D) -> void:
	set_show_range(tower == self)

func set_show_range(is_visible: bool) -> void:
	show_range = is_visible
	queue_redraw()

func _draw() -> void:
	if show_range and data:
		draw_circle(Vector2.ZERO, get_current_range(), Color(0.2, 0.8, 1.0, 0.2))
		
	if data and data.effect_type == "laser" and laser_targets.size() > 0:
		var color = Color(1.0, 0.0, 1.0) # Purple base
		if laser_heat_stacks >= 4 and GameManager.has_skill("olho_fusao"):
			color = Color(1.0, 0.5, 0.0) # Orange/Red when fusion maxed
		
		for t in laser_targets:
			if is_instance_valid(t):
				draw_line(Vector2.ZERO, to_local(t.global_position), color, 3.0)
				
		for chain in laser_chain_lines:
			if is_instance_valid(chain[0]) and is_instance_valid(chain[1]):
				draw_line(to_local(chain[0].global_position), to_local(chain[1].global_position), color, 1.5)

func _update_stats() -> void:
	if targeting_component:
		var col_shape = targeting_component.get_node("CollisionShape2D")
		if not col_shape.shape.resource_local_to_scene:
			col_shape.shape = col_shape.shape.duplicate()
			col_shape.shape.resource_local_to_scene = true
			
		if col_shape.shape is CircleShape2D: 
			col_shape.shape.radius = get_current_range()
			
	attack_timer.wait_time = get_current_cooldown()
	if attack_timer.is_stopped():
		attack_timer.start()
		
	queue_redraw()
	_find_valid_path_points()

var attacks_count = 0

func _process_laser_tick() -> void:
	if laser_targets.is_empty(): return
	
	var dmg = get_current_damage()
	if GameManager.has_skill("olho_dano_1"): dmg += 1
	if GameManager.has_skill("olho_calor_1"): dmg += laser_heat_stacks
	if GameManager.has_skill("olho_bifurcado"): dmg = int(max(1, dmg * 0.70))
	
	var is_crit = (laser_heat_stacks >= 4 and GameManager.has_skill("olho_fusao"))
	if is_crit: dmg = int(dmg * 2.0)
	
	for t in laser_targets:
		_deal_laser_damage(t, dmg, is_crit)
		
	for chain in laser_chain_lines:
		if is_instance_valid(chain[1]):
			_deal_laser_damage(chain[1], dmg, is_crit)

func _deal_laser_damage(tgt: Node2D, dmg: int, is_crit: bool) -> void:
	if not is_instance_valid(tgt) or not tgt.has_node("HealthComponent"): return
	
	if GameManager.has_skill("olho_satelite") and not tgt.has_meta("satelite_mark"):
		tgt.set_meta("satelite_mark", true)
		if tgt.has_method("apply_satelite_mark"):
			tgt.apply_satelite_mark(0.5)
			
	if GameManager.has_skill("olho_instant"):
		if tgt.has_method("apply_laser_slow"):
			tgt.apply_laser_slow(0.85, 0.5)
			
	var hc = tgt.get_node("HealthComponent")
	hc.take_damage(dmg)

func _on_attack_timer_timeout() -> void:
	if not data or not projectile_scene or not targeting_component: return
	
	if data.effect_type == "laser":
		_process_laser_tick()
		return
		
	if data.effect_type == "ice_aoe":
		return 
		
	if data.effect_type == "poison_path" or data.effect_type == "fire_path":
		_spawn_trap_randomly()
		return
		
	if data.tower_name == "Esqueleto (Básico)" and GameManager.has_skill("esqueleto_chuva"):
		attacks_count += 1
		if attacks_count >= 5:
			attacks_count = 0
			_fire_spiral()
			return
			
	var prioritize = (data.tower_name == "Esqueleto (Básico)" and GameManager.has_skill("esqueleto_mirada_alta"))
	var target = targeting_component.get_closest_target(global_position, prioritize)
	if target: _shoot(target)

func _fire_spiral() -> void:
	var count = randi_range(4, 6)
	for i in range(count):
		var angle = (float(i) / count) * TAU
		var dir = Vector2.RIGHT.rotated(angle)
		var proj = projectile_scene.instantiate()
		get_tree().current_scene.add_child(proj) 
		proj.global_position = global_position
		
		# Projéteis em espiral não seguem um alvo específico, então passamos o alvo nulo 
		# mas precisamos alterar o projétil para lidar com isso ou dar um alvo falso.
		# O ideal é achar o inimigo mais próximo naquela direção, ou disparar em linha reta.
		# Vamos pegar inimigos aleatórios para simular a espiral!
		var enemies = _get_valid_enemies()
		var tgt = enemies[i % enemies.size()] if enemies.size() > 0 else null
		if tgt:
			proj.setup(tgt, get_current_damage(), data.projectile_speed, data.color, data.effect_type, get_current_effect_value())
		else:
			proj.queue_free()

func _fire_projectile(target: Node2D) -> void:
	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj) 
	proj.global_position = global_position
	
	var eff = data.effect_type
	var eff_val = get_current_effect_value()
	
	if data.tower_name == "Esqueleto (Básico)":
		if GameManager.has_skill("esqueleto_estilhaco"): eff = "esqueleto_estilhaco"
		if GameManager.has_skill("esqueleto_maldicao"): eff = "esqueleto_maldicao"
		if GameManager.has_skill("esqueleto_perfurante"): eff = "esqueleto_perfurante"
		
	var dmg = get_current_damage()
	if randf() < get_crit_chance():
		dmg = int(dmg * 2.0)
		
	var p_speed = get_proj_speed()
		
	proj.setup(target, dmg, p_speed, data.color, eff, eff_val)

func _shoot(target: Node2D) -> void:
	if data.effect_type == "buff":
		_apply_buff_to_towers()
		return
		
	_fire_projectile(target)
	
	if data.tower_name == "Esqueleto (Básico)" and GameManager.has_skill("esqueleto_arco_duplo"):
		var enemies = _get_valid_enemies()
		if enemies.size() > 1:
			var second = enemies[0] if enemies[0] != target else enemies[1]
			_fire_projectile(second)
		else:
			_fire_projectile(target)


func _on_enemy_entered_aura(enemy: Node2D) -> void:
	if enemy.has_method("add_slow"):
		enemy.add_slow(get_current_effect_value())

func _on_enemy_exited_aura(enemy: Node2D) -> void:
	if enemy.has_method("remove_slow"):
		enemy.remove_slow(get_current_effect_value())

# Pool de armadilhas (fire_path/poison_path) reutilizáveis, para evitar criar/destruir
# Area2D+CollisionShape2D+Sprite2D a cada ataque (algumas torres atiram a cada 0.1s).
# Cada item do pool: { "area": Area2D, "sprite": Sprite2D }
var _trap_pool: Array = []
var _trap_spawn_counter: int = 0

func _get_pooled_trap() -> Dictionary:
	for entry in _trap_pool:
		if is_instance_valid(entry.area) and not entry.area.visible:
			return entry
	var entry = _create_trap_node()
	_trap_pool.append(entry)
	return entry

func _create_trap_node() -> Dictionary:
	var trap = Area2D.new()

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15.0
	col.shape = shape
	trap.add_child(col)

	var spr = Sprite2D.new()
	spr.texture = preload("res://icon.svg")
	spr.scale = Vector2(0.2, 0.2)
	trap.add_child(spr)

	trap.area_entered.connect(func(area): _on_trap_area_entered(area, trap))

	trap.hide()
	trap.monitoring = false
	get_tree().current_scene.add_child(trap)

	return { "area": trap, "sprite": spr }

func _spawn_trap_randomly() -> void:
	if valid_path_points.is_empty():
		return

	var random_pt = valid_path_points[randi() % valid_path_points.size()]
	var e_type = data.effect_type

	var entry = _get_pooled_trap()
	var trap: Area2D = entry.area
	var spr: Sprite2D = entry.sprite

	# Token de geração: identifica esta ativação específica da armadilha reaproveitada.
	# Sem isso, o timer de expiração de uma vida anterior (ex.: a armadilha morreu cedo
	# por ter sido pisada e já foi reaproveitada num novo spawn) esconderia a instância
	# atual antes da hora, prendendo o pool numa única armadilha sendo reciclada sem parar.
	_trap_spawn_counter += 1
	var spawn_id = _trap_spawn_counter

	trap.global_position = random_pt
	trap.set_meta("e_type", e_type)
	trap.set_meta("spawn_id", spawn_id)
	spr.modulate = data.color
	spr.modulate.a = 0.8
	trap.show()
	trap.monitoring = true

	var lifetime = 3.0 if e_type == "fire_path" else 10.0
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(func():
		if is_instance_valid(trap) and trap.get_meta("spawn_id", -1) == spawn_id:
			trap.hide()
			trap.monitoring = false
	)

func _on_trap_area_entered(area: Area2D, trap: Area2D) -> void:
	if area is HurtboxComponent and area.owner and area.owner.is_in_group("enemies"):
		var e_type = trap.get_meta("e_type", "")
		if e_type == "poison_path":
			if area.owner.has_method("apply_poison"):
				area.owner.apply_poison(get_current_damage(), 3.0)
			trap.hide()
			trap.monitoring = false
		elif e_type == "fire_path":
			if area.owner.has_method("apply_burn"):
				area.owner.apply_burn(get_current_damage(), 3.0)

func _exit_tree() -> void:
	for entry in _trap_pool:
		if is_instance_valid(entry.area):
			entry.area.queue_free()
	_trap_pool.clear()

func _spawn_spore_cloud() -> void:
	if valid_path_points.is_empty():
		return
	var random_pt = valid_path_points[randi() % valid_path_points.size()]
	
	var cloud = Area2D.new()
	cloud.global_position = random_pt
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 40.0
	col.shape = shape
	cloud.add_child(col)
	
	var spr = Sprite2D.new()
	spr.texture = preload("res://icon.svg")
	spr.scale = Vector2(0.6, 0.6)
	spr.modulate = Color(0.4, 0.8, 0.2, 0.5) # Verde meio transparente
	cloud.add_child(spr)
	
	get_tree().current_scene.add_child(cloud)
	
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(func(): if is_instance_valid(cloud): cloud.queue_free())
	
	cloud.area_entered.connect(func(area):
		if area is HurtboxComponent and area.owner and area.owner.is_in_group("enemies"):
			if area.owner.has_method("apply_poison"):
				area.owner.apply_poison(get_current_damage(), 3.0)
	)

func _on_texture_button_pressed() -> void:
	GameManager.tower_selected.emit(self)

func _apply_buff_to_towers() -> void:
	# Agora os buffs são aplicados passivamente pelas auras (ver getters).
	# Aqui podemos apenas colocar um efeito visual no futuro, se desejado.
	pass

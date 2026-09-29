import os

towers = [
    {'name': 'Espantalho (Buff)', 'file': 'espantalho.tres', 'cost': 150, 'range': 200.0, 'damage': 0, 'cooldown': 1.0, 'speed': 0.0, 'color': 'Color(1, 1, 0, 1)', 'effect': 'buff', 'evalue': 1.5},
    {'name': 'Esqueleto (Básico)', 'file': 'esqueleto.tres', 'cost': 50, 'range': 150.0, 'damage': 5, 'cooldown': 1.0, 'speed': 400.0, 'color': 'Color(0.8, 0.8, 0.8, 1)', 'effect': '', 'evalue': 0.0},
    {'name': 'Golem de Fogo (Chamas)', 'file': 'golem_fogo.tres', 'cost': 130, 'range': 120.0, 'damage': 2, 'cooldown': 0.1, 'speed': 300.0, 'color': 'Color(1, 0.3, 0, 1)', 'effect': 'fire_path', 'evalue': 3.0},
    {'name': 'Golem de Gelo (Lentidão)', 'file': 'golem_gelo.tres', 'cost': 120, 'range': 130.0, 'damage': 1, 'cooldown': 1.5, 'speed': 250.0, 'color': 'Color(0, 0.8, 1, 1)', 'effect': 'ice_aoe', 'evalue': 0.5},
    {'name': 'Golem de Pedra (Canhão)', 'file': 'golem_pedra.tres', 'cost': 150, 'range': 140.0, 'damage': 25, 'cooldown': 2.5, 'speed': 300.0, 'color': 'Color(0.5, 0.5, 0.5, 1)', 'effect': 'slow_hit', 'evalue': 0.5},
    {'name': 'Olho Flutuante (Laser)', 'file': 'olho.tres', 'cost': 200, 'range': 220.0, 'damage': 1, 'cooldown': 0.05, 'speed': 1000.0, 'color': 'Color(1, 0, 1, 1)', 'effect': 'laser', 'evalue': 0.0},
    {'name': 'Planta Peçonhenta', 'file': 'planta.tres', 'cost': 100, 'range': 130.0, 'damage': 3, 'cooldown': 1.5, 'speed': 200.0, 'color': 'Color(0, 1, 0, 1)', 'effect': 'poison_path', 'evalue': 3.0},
    {'name': 'Sapo (Sniper)', 'file': 'sapo.tres', 'cost': 250, 'range': 300.0, 'damage': 9999, 'cooldown': 4.0, 'speed': 800.0, 'color': 'Color(0.1, 0.5, 0.1, 1)', 'effect': 'instakill', 'evalue': 0.0}
]

template = '''[gd_resource type="Resource" script_class="TowerData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/tower_data.gd" id="1_2hfd5"]

[resource]
script = ExtResource("1_2hfd5")
tower_name = "{name}"
cost = {cost}
attack_range = {range}
attack_damage = {damage}
attack_cooldown = {cooldown}
projectile_speed = {speed}
color = {color}
effect_type = "{effect}"
effect_value = {evalue}
'''

for t in towers:
    content = template.format(**t)
    path = os.path.join('resources', 'towers', t['file'])
    with open(path, 'wb') as f:
        f.write(content.encode('utf-8'))
    print(f'Created {path}')

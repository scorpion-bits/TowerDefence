import re

with open('scripts/UI/skill_node.gd', 'r') as f:
    content = f.read()

content = content.replace('modulate = Color(1.0, 1.0, 0.2)', 'modulate = Color.WHITE')
content = content.replace('modulate = Color(0.5, 1.0, 0.5)', 'modulate = Color(0.8, 1.0, 0.8)')
content = content.replace('modulate = Color(1.0, 1.0, 1.0)', 'modulate = Color(0.5, 0.5, 0.5)')
content = content.replace('modulate = Color(0.3, 0.3, 0.3)', 'modulate = Color(0.15, 0.15, 0.15)')

with open('scripts/UI/skill_node.gd', 'w') as f:
    f.write(content)

import re

with open('scripts/UI/ui.gd', 'r') as f:
    content = f.read()

content = content.replace('selected_tower.data.attack_damage', 'selected_tower.get_current_damage()')
content = content.replace('selected_tower.data.attack_cooldown', 'selected_tower.get_current_cooldown()')
content = content.replace('selected_tower.data.attack_range', 'selected_tower.get_current_range()')

with open('scripts/UI/ui.gd', 'w') as f:
    f.write(content)

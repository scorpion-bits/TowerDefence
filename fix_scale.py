import os

# 1. Update wave_manager.gd to remove the 1.5x scaling
with open('scripts/Level/wave_manager.gd', 'r', encoding='utf-8') as f:
    wave = f.read()

wave = wave.replace('new_enemy.scale *= 1.5\n\t', '')

with open('scripts/Level/wave_manager.gd', 'w', encoding='utf-8') as f:
    f.write(wave)

# 2. Update enemy.tscn to scale down the AnimatedSprite2D
with open('scenes/enemy.tscn', 'r', encoding='utf-8') as f:
    tscn = f.read()

import re
tscn = re.sub(r'\[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="\.".*?\]\n', 
              '[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="." unique_id=1683765151]\nscale = Vector2(0.3, 0.3)\n', 
              tscn, flags=re.DOTALL)

with open('scenes/enemy.tscn', 'w', encoding='utf-8') as f:
    f.write(tscn)

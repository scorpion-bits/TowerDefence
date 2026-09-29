import os
import re

with open('scripts/Enemy/enemy.gd', 'r', encoding='utf-8') as f:
    content = f.read()

anim_logic = '''
var animation_timer: float = 0.0

func _process(delta: float) -> void:
	if data:
		progress += data.speed * delta
		
		if sprite and data.texture:
			animation_timer += delta * (data.speed / 15.0)
			sprite.frame = int(animation_timer) % 4
			
		if progress_ratio >= 1.0:
			_reach_end()
'''

content = re.sub(r'func _process\(delta: float\) -> void:.*?(?=\n\n|\Z)', anim_logic.strip(), content, flags=re.DOTALL)

with open('scripts/Enemy/enemy.gd', 'w', encoding='utf-8') as f:
    f.write(content)

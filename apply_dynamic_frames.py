import os
import re

with open('scripts/Enemy/enemy.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the texture assignment to also set hframes and vframes dynamically
tex_logic = '''if data.texture:
				sprite.texture = data.texture
				sprite.hframes = max(1, int(data.texture.get_width() / 64))
				sprite.vframes = max(1, int(data.texture.get_height() / 64))
			else: sprite.modulate = data.color'''

content = re.sub(r'if data\.texture: sprite\.texture = data\.texture\s+else: sprite\.modulate = data\.color', tex_logic, content)

# Replace the frame animation logic
anim_logic = '''if sprite and data.texture:
			animation_timer += delta * (data.speed / 15.0)
			sprite.frame = int(animation_timer) % sprite.hframes'''

content = re.sub(r'if sprite and data\.texture:\s+animation_timer \+= delta \* \(data\.speed / 15\.0\)\s+sprite\.frame = int\(animation_timer\) % 4', anim_logic, content)

with open('scripts/Enemy/enemy.gd', 'w', encoding='utf-8') as f:
    f.write(content)

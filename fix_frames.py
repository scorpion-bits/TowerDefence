import re
with open('scenes/enemy.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r'(\[node name="Sprite2D" type="Sprite2D" parent="\.".*?\]\n\s*texture = ExtResource\("3_nenq2"\))', 
    r'\1\nhframes = 4\nvframes = 4', 
    content
)

with open('scenes/enemy.tscn', 'w', encoding='utf-8') as f:
    f.write(content)

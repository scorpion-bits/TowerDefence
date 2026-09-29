import os

with open('scripts/Enemy/enemy.gd', 'r', encoding='utf-8') as f:
    enemy = f.read()

enemy = enemy.replace(r'\n\t', '\n\t')

with open('scripts/Enemy/enemy.gd', 'w', encoding='utf-8') as f:
    f.write(enemy)

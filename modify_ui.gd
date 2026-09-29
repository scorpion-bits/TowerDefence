extends SceneTree

func _init():
	var scene = load("res://scenes/ui.tscn") as PackedScene
	var root = scene.instantiate()
	
	var old_sidebar = root.get_node("SideBar")
	var btn_basic = old_sidebar.get_node("BtnBasic")
	var btn_sniper = old_sidebar.get_node("BtnSniper")
	var btn_mg = old_sidebar.get_node("BtnMG")
	
	old_sidebar.remove_child(btn_basic)
	old_sidebar.remove_child(btn_sniper)
	old_sidebar.remove_child(btn_mg)
	
	# Create new SideBar structure
	var panel = PanelContainer.new()
	panel.name = "BuildPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.set_offset(SIDE_RIGHT, -20)
	panel.set_offset(SIDE_TOP, -200)
	panel.set_offset(SIDE_BOTTOM, 200)
	panel.set_offset(SIDE_LEFT, -200) # Width 180
	
	var tab_container = TabContainer.new()
	tab_container.name = "TabContainer"
	panel.add_child(tab_container)
	tab_container.owner = root
	
	# Construir Tab
	var build_tab = MarginContainer.new()
	build_tab.name = "Construir"
	build_tab.add_theme_constant_override("margin_top", 10)
	build_tab.add_theme_constant_override("margin_bottom", 10)
	build_tab.add_theme_constant_override("margin_left", 10)
	build_tab.add_theme_constant_override("margin_right", 10)
	tab_container.add_child(build_tab)
	build_tab.owner = root
	
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	build_tab.add_child(scroll)
	scroll.owner = root
	
	var grid = GridContainer.new()
	grid.name = "GridContainer"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	grid.owner = root
	
	grid.add_child(btn_basic)
	btn_basic.owner = root
	btn_basic.custom_minimum_size = Vector2(70, 70)
	btn_basic.text = "$50"
	
	grid.add_child(btn_sniper)
	btn_sniper.owner = root
	btn_sniper.custom_minimum_size = Vector2(70, 70)
	btn_sniper.text = "$100"
	
	grid.add_child(btn_mg)
	btn_mg.owner = root
	btn_mg.custom_minimum_size = Vector2(70, 70)
	btn_mg.text = "$75"
	
	# Crafting Tab
	var craft_tab = MarginContainer.new()
	craft_tab.name = "Crafting"
	tab_container.add_child(craft_tab)
	craft_tab.owner = root
	var craft_label = Label.new()
	craft_label.text = "Crafting\nEm breve..."
	craft_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	craft_tab.add_child(craft_label)
	craft_label.owner = root
	
	# Replace old sidebar
	root.remove_child(old_sidebar)
	old_sidebar.queue_free()
	
	root.add_child(panel)
	panel.owner = root
	
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/ui.tscn")
	
	print("UI Modified!")
	quit()

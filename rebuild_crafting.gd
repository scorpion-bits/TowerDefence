extends SceneTree
func _init():
    var scene = load("res://scenes/ui.tscn") as PackedScene
    var root = scene.instantiate()
    
    var craft_tab = root.get_node("BuildPanel/TabContainer/Crafting")
    for c in craft_tab.get_children():
        c.queue_free()
        craft_tab.remove_child(c)
        
    var vbox = VBoxContainer.new()
    vbox.name = "CraftVBox"
    craft_tab.add_child(vbox)
    vbox.owner = root
    
    var inv_lbl = Label.new()
    inv_lbl.text = "Inventário"
    vbox.add_child(inv_lbl)
    inv_lbl.owner = root
    
    var inv_grid = GridContainer.new()
    inv_grid.name = "InventoryGrid"
    inv_grid.columns = 4
    vbox.add_child(inv_grid)
    inv_grid.owner = root
    
    var space = Control.new()
    space.custom_minimum_size = Vector2(0, 15)
    vbox.add_child(space)
    space.owner = root
    
    var cald_lbl = Label.new()
    cald_lbl.text = "Caldeirão (Clique nos itens)"
    vbox.add_child(cald_lbl)
    cald_lbl.owner = root
    
    var hbox = HBoxContainer.new()
    hbox.name = "SlotsHBox"
    vbox.add_child(hbox)
    hbox.owner = root
    
    for i in range(3):
        var slot = Button.new()
        slot.name = "Slot" + str(i)
        slot.custom_minimum_size = Vector2(40, 40)
        slot.text = ""
        hbox.add_child(slot)
        slot.owner = root
        
    var eq = Label.new()
    eq.text = " = "
    hbox.add_child(eq)
    eq.owner = root
    
    var result = Button.new()
    result.name = "ResultSlot"
    result.custom_minimum_size = Vector2(60, 60)
    result.disabled = true
    hbox.add_child(result)
    result.owner = root
    
    var craft_btn = Button.new()
    craft_btn.name = "CraftButton"
    craft_btn.text = "Craftar!"
    vbox.add_child(craft_btn)
    craft_btn.owner = root
    
    var clear_btn = Button.new()
    clear_btn.name = "ClearButton"
    clear_btn.text = "Limpar"
    vbox.add_child(clear_btn)
    clear_btn.owner = root
    
    var packed = PackedScene.new()
    packed.pack(root)
    ResourceSaver.save(packed, "res://scenes/ui.tscn")
    quit()

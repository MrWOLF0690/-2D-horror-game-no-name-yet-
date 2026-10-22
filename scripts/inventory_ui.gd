extends CanvasLayer

var panel: PanelContainer
var list: VBoxContainer
var hint: Label
var waiting_item: String = ""


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build_ui()
	panel.visible = false
	Inventory.inventory_changed.connect(func(_id, _n): _refresh())
	Inventory.hotkey_changed.connect(func(_id): _refresh())
	_refresh()
	
func _build_ui():
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 200)
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	
	var title = Label.new()
	title.text = "Inventory"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	
	list= VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	box.add_child(list)
	
	hint = Label.new()
	hint.text = "Press a button to change the hotkey  |  TAB or ESC to close the Inventory"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	
func _refresh():
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
		
	for item_id in Inventory.ITEMS:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		
		var name_label = Label.new()
		name_label.text = "%s  x%d" % [Inventory.ITEMS[item_id]["name"], Inventory.get_count(item_id)]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		
		var button = Button.new()
		button.custom_minimum_size = Vector2(170, 0)
		if waiting_item == item_id:
			button.text = "Press a Key..."
		else:
			button.text =  "Key: " + Inventory.get_hotkey_text(item_id)
		button.pressed.connect(_start_rebind.bind(item_id))
		row.add_child(button)
		
		list.add_child(row)
		
func _start_rebind(item_id: String):
	waiting_item = item_id
	_refresh()
	
func _input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
		
	if waiting_item != "":
		if event.keycode != KEY_ESCAPE:
			if not Inventory.set_hotkey(waiting_item, event.keycode):
				hint.text = "This Key is already in use, choose another?"
		waiting_item = ""
		_refresh()
		get_viewport().set_input_as_handled()
		return
		
	if event.keycode == KEY_TAB:
		_toggle()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and panel.visible:
		_toggle()
		get_viewport().set_input_as_handled()
		
func _toggle():
	panel.visible = not panel.visible
	get_tree().paused = panel.visible
	waiting_item = ""
	if panel.visible:
		hint.text = "Press a button to change the hotkey  |  TAB or ESC to close the Inventory"
		_refresh()

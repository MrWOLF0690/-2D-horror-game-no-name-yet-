extends CanvasLayer

var panel: PanelContainer
var list: VBoxContainer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build_ui()
	panel.visible = false
	Inventory.inventory_changed.connect(_on_inventory_changed)
	Inventory.hotkey_changed.connect(_on_hotkey_changed)
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
	
	var hint =  Label.new()
	hint.text = "TAB or ESC to close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	
func _on_inventory_changed(_item_id, _count):
	_refresh()
	
func _on_hotkey_changed(_item_id):
	_refresh()
	
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
		
		var key_label = Label.new()
		key_label.text = "[%s]" % Inventory.get_hotkey_text(item_id)
		row.add_child(key_label)
		
		list.add_child(row)
		
func _input(event):
	if SaveManager.pause_menu_open:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
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
	_refresh()

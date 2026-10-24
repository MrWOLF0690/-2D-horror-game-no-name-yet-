extends VBoxContainer

const DEFAULT_HINT = "Press to change bind. ESC to cancel"

var tabs: TabContainer
var controls_lists: VBoxContainer
var controls_hint: Label
var resolution_option: OptionButton
var waiting: Dictionary = {}

func _ready():
	custom_minimum_size = Vector2(560, 380)
	tabs = TabContainer.new()
	add_child(tabs)
	tabs.add_child(_build_audio_tab())
	tabs.add_child(_build_video_tab())
	tabs.add_child(_build_graphics_tab())
	tabs.add_child(_build_controls_tab())
	_refresh_controls()
	
func _exit_tree():
	Settings.save_settings()
	
func _make_tab(title: String) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.name = title
	box.add_theme_constant_override("separation", 14)
	return box

func _label(text: String) -> Label:
	var l = Label.new()
	l.text = text
	return l
	
func _header(text: String) -> Label:
	var l = _label(text)
	l.add_theme_font_size_override("font_size", 20)
	return l
	
func _make_button(text: String, callback: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.pressed.connect(callback)
	return b
	
func _build_audio_tab() -> Control:
	var box = _make_tab("Audio")
	box.add_child(_label("General Volume"))
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = Settings.master_volume
	slider.custom_minimum_size = Vector2(0, 32)
	slider.value_changed.connect(_on_volume_changed)
	box.add_child(slider)
	return box
	
func _on_volume_changed(value: float):
	Settings.master_volume = value
	Settings.apply_audio()
	
func _build_video_tab() -> Control:
	var box = _make_tab("Video")
	
	box.add_child(_label("Window mode resolution"))
	resolution_option = OptionButton.new()
	for r in Settings.RESOLUTIONS:
		resolution_option.add_item("%d x %d" % [r.x, r.y])
	resolution_option.selected = Settings.resolution_index
	resolution_option.disabled = Settings.fullscreen
	resolution_option.item_selected.connect(_on_resolution_selected)
	box.add_child(resolution_option)
	
	var fs = CheckButton.new()
	fs.text = "Fullscreen"
	fs.button_pressed = Settings.fullscreen
	fs.toggled.connect(_on_fullscreen_toggled)
	box.add_child(fs)
	return box
	
func _on_resolution_selected(index: int):
	Settings.resolution_index = index
	Settings.apply_video()
	Settings.save_settings()
	
func _on_fullscreen_toggled(on: bool):
	Settings.fullscreen = on
	resolution_option.disabled = on
	Settings.apply_video()
	Settings.save_settings()
	
func _build_graphics_tab() -> Control:
	var box = _make_tab("Graphics")
	
	var vs = CheckButton.new()
	vs.text = "VSync"
	vs.button_pressed = Settings.vsync
	vs.toggled.connect(_on_vsync_toggled)
	box.add_child(vs)
	
	box.add_child(_label("Anti-aliasing (MSAA 3D)"))
	var msaa = OptionButton.new()
	for t in ["off", "2x", "4x", "8x"]:
		msaa.add_item(t)
	msaa.selected = Settings.msaa_index
	msaa.item_selected.connect(_on_msaa_selected)
	box.add_child(msaa)
	
	box.add_child(_label("FPS LIMIT"))
	var fps = OptionButton.new()
	for t  in ["Unlimited", "30", "60", "120", "144"]:
		fps.add_item(t)
	fps.selected = Settings.fps_index
	fps.item_selected.connect(_on_fps_selected)
	box.add_child(fps)
	return box
	
func _on_vsync_toggled(on: bool):
	Settings.vsync = on
	Settings.apply_graphics()
	Settings.save_settings()
	
func _on_msaa_selected(index: int):
	Settings.msaa_index = index
	Settings.apply_graphics()
	Settings.save_settings()
	
func _on_fps_selected(index: int):
	Settings.fps_index = index
	Settings.apply_graphics()
	Settings.save_settings()
	
func _build_controls_tab() -> Control:
	var box = _make_tab("Controlls")
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	
	controls_lists = VBoxContainer.new()
	controls_lists.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_lists.add_theme_constant_override("separation", 8)
	scroll.add_child(controls_lists)
	
	controls_hint = _label(DEFAULT_HINT)
	box.add_child(controls_hint)
	box.add_child(_make_button("Reset keybinds", _on_reset_controls))
	return box
	
func _refresh_controls():
	if controls_lists == null:
		return
	for child in controls_lists.get_children():
		controls_lists.remove_child(child)
		child.queue_free()
		
	controls_lists.add_child(_header("Movement"))
	for action in Settings.MOVE_ACTIONS:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var name_label = _label(Settings.MOVE_ACTIONS[action])
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		for slot in range(2):
			row.add_child(_key_button(Settings.get_move_key_text(action, slot), "move", action, slot))
		controls_lists.add_child(row)
		
	controls_lists.add_child(_header("Items"))
	for item_id in Inventory.ITEMS:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var name_label = _label(Inventory.ITEMS[item_id]["name"])
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(_key_button(Inventory.get_hotkey_text(item_id), "item", item_id, 0))
		
func _key_button(text: String, kind: String, id: String, slot: int) -> Button:
	var b = Button.new()
	b.custom_minimum_size = Vector2(130, 36)
	var is_waiting = not waiting.is_empty() and waiting["kind"] == kind and waiting["slot"] == slot
	b.text = "Press a Key..." if is_waiting else text
	b.pressed.connect(_start_rebind.bind(kind, id, slot))
	return b
	
func _start_rebind(kind: String, id: String, slot: int):
	waiting = {"kind": kind, "id": id, "slot": slot}
	controls_hint.text = "Press a Key (ESC to cancel)..."
	_refresh_controls()
	
func _input(event):
	if waiting.is_empty():
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	get_viewport().set_input_as_handled()
	
	var key = event.keycode
	if key == KEY_ESCAPE:
		_cancel_rebind()
		return
	if Settings.is_reserved(key):
		controls_hint.text = "Key already bound to action, choose another"
		return
		
	if waiting["kind"] == "move":
		Settings.assign_move_key(waiting["id"], waiting["slot"], key)
	else:
		Settings.assign_item_key(waiting["id"], key)
	_cancel_rebind()
	
func _cancel_rebind():
	waiting = {}
	controls_hint.text = DEFAULT_HINT
	_refresh_controls()
	

func _on_reset_controls():
	Settings.reset_bindings()
	Inventory.reset_hotkeys()
	_cancel_rebind()

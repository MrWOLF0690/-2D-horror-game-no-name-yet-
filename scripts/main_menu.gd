extends Control

const GAME_TITLE = "The Iron Foundry"
const SettingsPanel = preload("res://settings_panel.gd")


var pages: Dictionary = {}
var slot_mode: String = "load"
var slot_title: Label
var slot_list: VBoxContainer
var confirm: ConfirmationDialog
var pending_slot: int = -1
var pending_action: String = ""

func _ready():
	Sanity.tracking = false
	SaveManager.in_game = false
	get_tree().paused = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_show_page("main")
	
func _build_ui():
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.05)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var center = CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var holder = VBoxContainer.new()
	holder.custom_minimum_size = Vector2(560, 0)
	holder.add_theme_constant_override("separation", 24)
	center.add_child(holder)
	
	var title = Label.new()
	title.text = GAME_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	holder.add_child(title)
	
	pages["main"] = _build_main_page()
	pages["slots"] = _build_slots_page()
	for page in pages.values():
		holder.add_child(page)
		
	confirm = ConfirmationDialog.new()
	add_child(confirm)
	confirm.confirmed.connect(_on_confirmed)
	
func _button(text: String, callback: Callable) -> Button:
	var b = Button.new()
	b.text  = text
	b.custom_minimum_size = Vector2(0, 48)
	b.pressed.connect(callback)
	return b
	
func _show_page(page_name: String):
	for key in pages:
		pages[key].visible = (key == page_name)
		
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and not pages["main"].visible:
		if pages["Settings"].visible:
			Settings.save_settings()
		_show_page("main")
		
func _build_main_page() -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.add_child(_button("New Game", _open_slots.bind("new")))
	box.add_child(_button("Continue", _open_slots.bind("load")))
	box.add_child(_button("Settings", _show_page.bind("settings")))
	box.add_child(_button("Leave Game", _quit))
	return box
	
func _quit():
	get_tree().quit()
	
func _build_slots_page() -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	
	slot_title  = Label.new()
	slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_title.add_theme_font_size_override("font_size", 24)
	box.add_child(slot_title)
	
	slot_list = VBoxContainer.new()
	slot_list.add_theme_constant_override("separaton", 8)
	box.add_child(slot_list)
	
	box.add_child(_button("Back", _show_page.bind("main")))
	return box
	
func _open_slots(mode: String):
	slot_mode = mode
	slot_title.text = "Choose a new save file" if mode == "new" else "Choose a saved game"
	_refresh_slots()
	_show_page("slots")
	
func _refresh_slots():
	for child in slot_list.get_children():
		slot_list.remove_child(child)
		child.queue_free()
		
	for slot in range(SaveManager.SLOT_COUNT):
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		
		var info = SaveManager.get_slot_info(slot)
		var main_btn = Button.new()
		main_btn.custom_minimum_size = Vector2(0, 64)
		main_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if info.is_empty():
			main_btn.text = "Slot %d - Empty" % (slot + 1)
			main_btn.disabled = (slot_mode == "load")
		else:
			main_btn.text = "Slot %d - %s - %s - Sanity %d%%" % [
				slot + 1, _format_time(info["playtime"]), info["saved_at"], int(info["sanity"])
			]
		main_btn.pressed.connect(_on_slot_pressed.bind(slot))
		row.add_child(main_btn)
		
		if not info.is_empty():
			var del = Button.new()
			del.text = "Delete"
			del.custom_minimum_size = Vector2(90, 64)
			del.pressed.connect(_ask_delete.bind(slot))
			row.add_child(del)
			
		slot_list.add_child(row)
		
func _on_slot_pressed(slot: int):
	var exists = SaveManager.slot_exists(slot)
	if slot_mode == "new":
		if exists:
			pending_slot = slot
			pending_action = "overwrite"
			confirm.dialog_text = "The slot %d already has a save. Overwire it?" %(slot + 1)
			confirm.popup_centered()
		else:
			SaveManager.new_game(slot)
	else:
		SaveManager.new_game(slot)
		
func _ask_delete(slot: int):
	pending_slot = slot
	pending_action = "delete"
	confirm.dialog_text = "Permanently delete save game %d?" % (slot + 1)
	confirm.popup_centered()
	
func _on_confirmed():
	match pending_action:
		"overwrite":
			SaveManager.new_game(pending_slot)
		"delete":
			SaveManager.delete_slot(pending_slot)
			_refresh_slots()
			
func _format_time(seconds: float) -> String:
	var s = int(seconds)
	return "%02d:%02d:%02d" % [floori(s / 3600.0), floori((s % 3600) / 60), s % 60]
	
func _build_settings_page() -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	box.add_child(SettingsPanel.new())
	box.add_child(_button("Back", _on_settings_back))
	return box
	
func _on_settings_back():
	Settings.save_settings()
	_show_page("main")
	
func _on_volume_changed(value: float):
	Settings.master_volume = value
	Settings.apply()
	
func _on_fullscreen_toggled(on: bool):
	Settings.fullscreen = on
	Settings.apply()
	
	
func _on_settings_back_if_needed():
	if pages["settings"].visible:
		Settings.save_settings()

extends CanvasLayer

const SettingsPanel = preload("res://settings_panel.gd")

var root: Control
var main_page: VBoxContainer
var settings_page: VBoxContainer
var status_label: Label
var confirm: ConfirmationDialog
var pending_exit: String = ""
var is_open: bool = false	

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_build_ui()
	root.visible = false
	
func _build_ui():
	root = Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var center = CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var holder = VBoxContainer.new()
	holder.custom_minimum_size = Vector2(560, 0)
	holder.add_theme_constant_override("separation", 20)
	center.add_child(holder)
	
	var title = Label.new()
	title.text = "Game paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	holder.add_child(title)
	
	main_page = VBoxContainer.new()
	main_page.add_theme_constant_override("separation", 12)
	main_page.add_child(_button("Resume Game", _close))
	main_page.add_child(_button("Settings", _show_settings))
	main_page.add_child(_button("Save Game", _save))
	main_page.add_child(_button("Main Menu", _ask_exit.bind("menu")))
	main_page.add_child(_button("Quit Game", _ask_exit.bind("quit")))
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_page.add_child(status_label)
	holder.add_child(main_page)
	
	settings_page = VBoxContainer.new()
	settings_page.add_theme_constant_override("separation", 16)
	settings_page.add_child(SettingsPanel.new())
	settings_page.add_child(_button("Back", _on_settings_back))
	holder.add_child(settings_page)
	settings_page.visible = false
	
	confirm = ConfirmationDialog.new()
	confirm.title = "Exit"
	confirm.dialog_text = "Do you want to save the game before exiting?"
	confirm.ok_button_text = "Save and exit"
	confirm.cancel_button_text = "Cancel"
	confirm.add_button("Exit without saving", true, "nosave")
	confirm.confirmed.connect(_on_exit_save)
	confirm.custom_action.connect(_on_exit_custom)
	root.add_child(confirm)
	
func _button(text: String, callback: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.pressed.connect(callback)
	return b
	
func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode != KEY_ESCAPE:
		return
	get_viewport().set_input_as_handled()
	if not is_open:
		_open()
	elif settings_page.visible:
		Settings.save_settings()
		_show_main()
	else:
		_close()
		
func _open():
	is_open = true
	SaveManager.pause_menu_open = true
	root.visible = true
	_show_main()
	get_tree().paused = true
	
func _close():
	is_open = false
	SaveManager.pause_menu_open = false
	root.visible = false
	get_tree().paused = false
	
func _show_main():
	main_page.visible = true
	settings_page.visible = false
	status_label.text = ""
	
func _show_settings():
	main_page.visible = false
	settings_page.visible = true
	
func _on_settings_back():
	Settings.save_settings()
	_show_main()
	
func _save():
	if SaveManager.save_game():
		status_label.text = "Game Saved"
	else:
		status_label.text = "Couldn't save game"
		
func _ask_exit(kind: String):
	pending_exit = kind
	confirm.popup_centered()
	
func _on_exit_save():
	_do_exit(true)
	
func _on_exit_custom(action: StringName):
	if action == &"nosave":
		confirm.hide()
		_do_exit(false)
		
func _do_exit(save: bool):
	if pending_exit == "menu":
		SaveManager.return_to_menu(save)
	else:
		SaveManager.quit_game(save)

extends CanvasLayer

const TUTORIAL_KEYS = {
	KEY_W: "W",
	KEY_A: "A",
	KEY_S: "S",
	KEY_D: "D",
}

var pressed = {}
var key_labels = {}
var panel: PanelContainer
var finished = false

func _ready():
	_build_ui()
	
func _build_ui():
	panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.offset_top = 30
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",24)
	margin.add_theme_constant_override("margin_right",24)
	margin.add_theme_constant_override("margin_top",16)
	margin.add_theme_constant_override("margin_bottom",16)
	panel.add_child(margin)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title = Label.new()
	title.text = "Move using WASD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	for keycode in TUTORIAL_KEYS:
		var label = Label.new()
		label.text = TUTORIAL_KEYS[keycode]
		label.custom_minimum_size = Vector2(48, 48)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 28)
		row.add_child(label)
		key_labels[keycode] = label


func _input(event):
	if finished:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.physical_keycode
		if TUTORIAL_KEYS.has(key) and not pressed.has(key):
			pressed[key] = true
			key_labels[key].add_theme_color_override("font_color", Color.LIME_GREEN)
			if pressed.size() == TUTORIAL_KEYS.size():
				_finish()


func _finish():
	finished = true
	await get_tree().create_timer(0.6).timeout   # scurtă pauză, să vadă că le-a apăsat pe toate
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	await tween.finished

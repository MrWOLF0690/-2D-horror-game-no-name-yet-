extends  CanvasLayer

@export var tutorial_texture: Texture2D
@export var display_scale: float = 3.0
@export var vertical_offset: float = 0.0

const  REQUIRED_ACTIONS = ["move_up", "move_down", "move_left", "move_right"]

var pressed = {}
var sprite: TextureRect
var finished = false

func _ready():
	if SaveManager.tutorial_done:
		queue_free()
		return
		
	if tutorial_texture == null:
		push_error("Tutorial: trage sprite-ul in campul Tutorial Texture")
		finished = true
		return
		
	sprite = TextureRect.new()
	sprite.texture = tutorial_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.custom_minimum_size = tutorial_texture.get_size() * display_scale
	add_child(sprite)
	sprite.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	sprite.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sprite.grow_vertical = Control.GROW_DIRECTION_BOTH
	sprite.position.y += vertical_offset
	
func _input(event):
	if finished:
		return
	for action in REQUIRED_ACTIONS:
		if event.is_action_pressed(action) and not pressed.has(action):
			pressed[action] = true
		if pressed.size() == REQUIRED_ACTIONS.size():
			_finish()

func _finish():
	finished = true
	SaveManager.tutorial_done = true
	SaveManager.save_game()
	await get_tree().create_timer(0.6).timeout
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()

extends CanvasLayer

@export var state_textures: Array[Texture2D] = []

@onready var icon: TextureRect = $Icon

func _ready():
	Sanity.state_changed.connect(_update_icon)
	_update_icon(Sanity.current_state)
	
func _update_icon(state: int):
	if state_textures.is_empty():
		return
	icon.texture = state_textures[clamp(state, 0, state_textures.size() - 1)]

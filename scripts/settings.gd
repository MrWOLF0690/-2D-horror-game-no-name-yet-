extends Node

const PATH = "user://settings.cfg"

const  RESOLUTIONS = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const MSAA_MODES = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_8X]
const FPS_LIMITS = [0, 30, 60, 120, 144]

const MOVE_ACTIONS = {
	"move_up": "Up",
	"move_down": "Down",
	"move_left": "Left",
	"move_right": "Right",
}
const  DEFAULT_BINDINGS = {
	"move_up": [KEY_W],
	"move_down": [KEY_S],
	"move_left": [KEY_A],
	"move_right": [KEY_D],
}
const RESERVED_KEYS = [KEY_ESCAPE, KEY_TAB, KEY_E]

var master_volume: float = 0.8
var fullscreen: bool = false
var resolution_index: int = 0
var vsync: bool = true
var msaa_index: int = 0
var fps_index: int = 0
var bindings: Dictionary = {}

func _ready():
	bindings = DEFAULT_BINDINGS.duplicate(true)
	load_settings()
	apply_bindings()
	apply_all()
	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_settings()
		
func load_settings():
	var cfg = ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = float(cfg.get_value("audio", "master_volume", master_volume))
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	resolution_index = clampi(int(cfg.get_value("video", "resolution", resolution_index)), 0, RESOLUTIONS.size() - 1)
	vsync = bool(cfg.get_value("graphics", "vsync", vsync))
	msaa_index = clampi(int(cfg.get_value("graphics", "msaa_index", msaa_index)), 0, MSAA_MODES.size() - 1)
	fps_index = clampi(int(cfg.get_value("graphics", "fps_index", fps_index)), 0, FPS_LIMITS.size() - 1)
	for action in bindings:
		var saved = cfg.get_value("controls", action, bindings[action])
		if saved is Array and saved.size() == 2:
			bindings[action] = [int(saved[0]), int(saved[1])]
			
func save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "resolution_index", resolution_index)
	cfg.set_value("graphics", "vsync", vsync)
	cfg.set_value("graphics", "msaa_index", msaa_index)
	cfg.set_value("graphics", "fps_index", fps_index)
	for action in bindings:
		cfg.set_value("controls", action, bindings[action])
	cfg.save(PATH)
	
func apply_all():
	apply_audio()
	apply_video()
	apply_graphics()
	
func apply_audio():
	AudioServer.set_bus_volume_db(0, linear_to_db(max(master_volume, 0.0001)))
	AudioServer.set_bus_mute(0, master_volume <= 0.001)
	
func apply_video():
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var target_size = RESOLUTIONS[resolution_index]
	DisplayServer.window_set_size(target_size)
	var screen = DisplayServer.window_get_current_screen()
	var screen_pos = DisplayServer.screen_get_position(screen)
	var screen_size = DisplayServer.screen_get_size(screen)
	DisplayServer.window_set_position(screen_pos + (screen_size - target_size) / 2)
	
func apply_graphics():
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d = MSAA_MODES[msaa_index]
	Engine.max_fps = FPS_LIMITS[fps_index]
	
func apply_bindings():
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		for key in bindings[action]:
			if key != KEY_NONE:
				var ev = InputEventKey.new()
				ev.keycode = key 
				InputMap.action_add_event(action, ev)
				
func get_move_key_text(action: String, slot: int) -> String:
	var keys = bindings.get(action, [])
	if slot >= keys.size() or keys[slot] == KEY_NONE:
		return "-"
	return OS.get_keycode_string(keys[slot])
	
	
func assign_move_key(action: String, slot: int, keycode: Key):
	_free_key(keycode)
	bindings[action][slot] = keycode
	apply_bindings()
	save_settings()
	
func assign_item_key(item_id: String, keycode: Key):
	_free_key(keycode)
	Inventory.set_hotkey(item_id, keycode)
	
func reset_bindings():
	bindings = DEFAULT_BINDINGS.duplicate(true)
	apply_bindings()
	save_settings()
	
func _free_key(keycode: Key):
	for action in bindings:
		for i in bindings[action].size():
			if bindings[action][i] == keycode:
				bindings[action][i] = KEY_NONE
	for item_id in Inventory.hotkeys:
		if Inventory.hotkeys[item_id] == keycode:
			Inventory.clear_hotkey(item_id)

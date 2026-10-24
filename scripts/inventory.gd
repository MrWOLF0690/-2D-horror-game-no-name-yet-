extends Node

signal inventory_changed(item_id: String, new_count: int)
signal hotkey_changed(item_id: String)
signal item_used(item_id: String)

const SANITY_PILL_RESTORE = 25.0
#AICI ADAUG ITEME PE VIITOR!!!
const ITEMS = {
	"sanity_pill": {"name": "Sanity Pill", "default_key": KEY_Q},
}
const RESERVED_KEYS = [KEY_E, KEY_TAB, KEY_ESCAPE]
const HOTKEY_PATH = "user://hotkeys.cfg"

var items: Dictionary = {}
var hotkeys: Dictionary = {}

func _ready():
	for item_id in ITEMS:
		hotkeys[item_id] = ITEMS[item_id]["default_key"]
	_load_hotkeys()
		
func _load_hotkeys():
	var cfg = ConfigFile.new()
	if cfg.load(HOTKEY_PATH) != OK:
		return	
	for item_id in hotkeys:
		hotkeys[item_id] = int(cfg.get_value("hotkeys", item_id, hotkeys[item_id]))
		
func _save_hotkeys():
	var cfg = ConfigFile.new()
	for item_id in hotkeys:
		cfg.set_value("hotkeys", item_id, hotkeys[item_id])
	cfg.save(HOTKEY_PATH)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		for item_id in hotkeys:
			if hotkeys[item_id] == event.keycode:
				use_item(item_id)
				get_viewport().set_input_as_handled()
				return
				
func add_item(item_id: String, amount: int = 1):
	items[item_id] = get_count(item_id) + amount
	inventory_changed.emit(item_id, items[item_id])
	
func get_count(item_id: String) -> int:
	return items.get(item_id, 0)
	
func has_item(item_id: String) -> bool:
	return get_count(item_id) > 0
	
func can_use(item_id: String) -> bool:
	if not has_item(item_id):
		return false
	match item_id:
		"sanity_pill":
			return Sanity.sanity < Sanity.MAX_SANITY
	return true
	
func use_item(item_id: String) -> bool:
	if not can_use(item_id):
		return false
		
	items[item_id] -= 1
	inventory_changed.emit(item_id, items[item_id])
	
	match item_id:
		"sanity_pill":
			Sanity.change(SANITY_PILL_RESTORE)
			
	item_used.emit(item_id)
	return true
	

func set_hotkey(item_id: String, keycode: Key) -> bool:
	if keycode in RESERVED_KEYS:
		return false
	for other in hotkeys:
		if other != item_id and hotkeys[other] == keycode:
			hotkeys[other] = KEY_NONE
			hotkey_changed.emit(other)
	hotkeys[item_id] = keycode
	hotkey_changed.emit(item_id)
	_save_hotkeys()
	return true
	
func get_hotkey_text(item_id: String) -> String:
	var key = hotkeys.get(item_id, KEY_NONE)
	if key == KEY_NONE:
		return "-"
	return OS.get_keycode_string(key)

func get_save_data() -> Dictionary:
	return {"items": items}
	
func load_save_data(data: Dictionary):
	items = {}
	var saved = data.get("items", {})
	for id in saved:
		items[id] = int(saved[id])
		
func reset_items():
	items = {}

func clear_hotkey(item_id: String):
	hotkeys[item_id] = KEY_NONE
	_save_hotkeys()
	hotkey_changed.emit(item_id)
	
func reset_hotkeys():
	for item_id in ITEMS:
		hotkeys[item_id] = ITEMS[item_id]["default_key"]
		hotkey_changed.emit(item_id)
	_save_hotkeys()

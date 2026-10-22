extends Node

signal inventory_changed(item_id: String, new_count: int)
signal hotkey_changed(item_id: String)
signal item_used(item_id: String)

const SANITY_PILL_RESTORE = 25.0
#AICI ADAUG ITEME PE VIITOR!!!
const ITEMS = {
	"sanity_pill": {"name": "Sanity Pill", "default_key": KEY_Q},
}
const RESERVED_KEYS = [KEY_W, KEY_A, KEY_S, KEY_D, KEY_E, KEY_TAB, KEY_ESCAPE]

var items: Dictionary = {}
var hotkeys: Dictionary = {}

func _ready():
	for item_id in ITEMS:
		hotkeys[item_id] = ITEMS[item_id]["default_key"]
		
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
	return true
func get_hotkey_text(item_id: String) -> String:
	var key = hotkeys.get(item_id, KEY_NONE)
	if key == KEY_NONE:
		return "-"
	return OS.get_keycode_string(key)

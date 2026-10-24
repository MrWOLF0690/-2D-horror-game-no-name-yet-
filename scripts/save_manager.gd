extends Node

const  SLOT_COUNT = 3
const  GAME_SCENE = "res://main.tscn"
const MENU_SCENE = "res://main_menu.tscn"

var current_slot: int = -1
var in_game: bool = false
var playtime: float = 0.0
var collected_pickups: Array = []
var tutorial_done: bool = false
var pause_menu_open: bool = false
var _pending_load: Dictionary = {}

func _process(delta):
	if in_game:
		playtime += delta
		
func _slot_path(slot: int) -> String:
	return "user://save_%d.json" % slot
	
func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))
	
func _read(slot: int) -> Dictionary:
	var file = FileAccess.open(_slot_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
	
func get_slot_info(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {}
	var data = _read(slot)
	if data.is_empty():
		return {}
	return {
		"playtime": data.get("playtime", 0.0),
		"saved_at": data.get("saved_at", ""),
		"sanity": data.get("sanity",{}).get("sanity", 100.0),
	}
	
func delete_slot(slot: int):
	if slot_exists(slot):
		DirAccess.open("user://").remove("save_%d.json" % slot)
		
func new_game(slot: int):
	current_slot = slot
	playtime = 0.0
	collected_pickups = []
	tutorial_done = false
	Sanity.reset()
	Inventory.reset_items()
	_pending_load = {}
	_start_game()
	
func load_game(slot: int) -> bool:
	var data = _read(slot)
	if data.is_empty():
		return false
	current_slot = slot
	playtime = data.get("playtime", 0.0)
	collected_pickups = data.get("collected_pickups", [])
	tutorial_done = data.get("tutorial_done", false)
	Sanity.load_save_data(data.get("sanity", {}))
	Inventory.load_save_data(data.get("inventory", {}))
	_pending_load = data
	_start_game()
	return true
	
func save_game() -> bool:
	if current_slot < 0:
		return false
		
	var data = {
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"playtime": playtime,
		"Sanity": Sanity.get_save_data(),
		"Inventory": Inventory.get_save_data(),
		"collected_pickups": collected_pickups,
		"tutorial_done": tutorial_done,
	}
	var player = _find_player()
	if player:
		var p = player.global_position
		data["player_pos"] = [p.x, p.y, p.z]
		
	var file = FileAccess.open(_slot_path(current_slot), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true
	
func return_to_menu(save: bool = true):
	if save:
		save_game()
	in_game = false
	Sanity.tracking = false
	get_tree().paused =false
	get_tree().change_scene_to_file(MENU_SCENE)
	
func _start_game():
	pause_menu_open = false
	Sanity.tracking = true
	in_game = true
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)
	await  get_tree().process_frame
	await get_tree().process_frame
	_apply_player_position()
	if not slot_exists(current_slot):
		save_game()
		
func _find_player() -> Node3D:
	var scene = get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("Player", true, false) as Node3D
	
func _apply_player_position():
	var player = _find_player()
	if player and _pending_load.has("player_pos"):
		var p = _pending_load["player_pos"]
		player.global_position = Vector3(p[0], p[1], p[2])
	_pending_load = {}
	
func is_collected(key: String) -> bool:
	return key in collected_pickups
	
func mark_collected(key: String):
	if key not in collected_pickups:
		collected_pickups.append(key)

func quit_game(save: bool = true):
	if save:
		save_game()
	get_tree().quit()

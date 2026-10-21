extends Area3D

@export var item_id: String = "sanity_pill"
@export var amount: int = 1
@export var require_interact: bool = false

var player_in_range: bool = false 

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _on_body_entered(body):
	if body is CharacterBody3D:
		if require_interact:
			player_in_range = true
		else:
			_pick_up()
			
func _on_body_exited(body):
	if body is CharacterBody3D:
		player_in_range = false
		
func _unhandled_input(event):
	if require_interact and player_in_range:
		if event is InputEventKey and event.pressed and event.keycode == KEY_E:
			_pick_up()
			
func _pick_up():
	Inventory.add_item(item_id, amount)
	queue_free()

extends Camera3D

@export var follow_speed: float = 6.0
@export var deadzone: float = 2.0
@export var left_limit: float = -10.0
@export var right_limit: float = 10.0

var start_y: float
var start_z: float
var target: Node3D

func _ready():
	target = get_parent() as Node3D
	var start_pos = global_position
	top_level = true
	global_position = start_pos
	start_y = global_position.y
	start_z = global_position.z
		
func _process(delta):
	if target == null:
		return	
	var cam_x = global_position.x
	var diff = target.global_position.x - cam_x
	var desired_x = cam_x
	
	if diff > deadzone:
		desired_x = target.global_position.x - deadzone
	elif diff < -deadzone:
		desired_x = target.global_position.x + deadzone
		
	var new_x = lerp(cam_x, desired_x, follow_speed * delta)
	global_position = Vector3(new_x, start_y, start_z)

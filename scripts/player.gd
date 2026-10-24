extends CharacterBody3D

const SPEED = 1.5

@onready var animated_sprite: AnimatedSprite3D = get_node_or_null("AnimatedSprite3D")

var last_facing = "down"

func _ready():
	if animated_sprite == null:
		push_error("No node AnimatedSprite3D Found")
		
func _physics_process(delta):
	var speed = SPEED * Sanity.get_speed_mulyiplier()
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = Vector3(input_dir.x, -input_dir.y, 0).normalized()
	var moving = direction != Vector3.ZERO
	
	if moving:
		velocity.x = direction.x * SPEED
		velocity.y = direction.y * SPEED
		if abs(direction.y) > abs(direction.x):
			last_facing = "up" if direction.y > 0 else "down"
		else:
			last_facing = "left" if direction.x < 0 else "right"
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
	velocity.z = 0
	
	move_and_slide()
	_update_animation(moving)
	
func _play(anim: String):
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames.has_animation(anim):
		animated_sprite.play(anim)
	else:
		push_warning("animation missing")
		
func _update_animation(moving: bool):
	if animated_sprite == null:
		return
	match last_facing:
		"up":
			_play("walk_up" if moving else "idle_up")
		"down":
			_play("walk_down" if moving else "idle_down")
		"left":
			animated_sprite.flip_h = true
			_play("walk" if moving else "idle_side")
		"right":
			animated_sprite.flip_h = false
			_play("walk" if moving else "idle_side")
			
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_MINUS:
			Sanity.change(-3)
		elif event.keycode == KEY_EQUAL:
			Sanity.change(3)

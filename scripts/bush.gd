extends Node3D
@export var faded_alpha: float = 0.35
@export var fade_time: float = 0.2

@onready var sprite: Sprite3D = $Sprite3D
@onready var area: Area3D = $Area3D

var tween: Tween

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is CharacterBody3D:
		_fade_to(faded_alpha)
		
func _on_body_exited(body):
	if body is CharacterBody3D:
		_fade_to(1.0)
		
func _fade_to(target_alpha: float):
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(sprite, "modulate:a", target_alpha, fade_time)

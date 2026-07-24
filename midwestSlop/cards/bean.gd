extends CharacterBody2D

const JUMP_VELOCITY = -600.0
var gravity = 1500.0

func _physics_process(delta):
	if not get_parent().is_playing: return 
	
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()

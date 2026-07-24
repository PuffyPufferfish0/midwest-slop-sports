extends Node2D

var obstacle_scene = preload("res://cards/obstacle.tscn")
var base_speed = 400.0
var current_speed = 400.0
var is_playing = false
var active_player = null

@onready var timer = $Timer
@onready var bean = $Bean

@onready var bean_start_pos = bean.position 

func start_game(player):
	active_player = player
	is_playing = true
	current_speed = base_speed
	
	bean.position = bean_start_pos 
	
	for child in get_children():
		if child.is_in_group("obstacles"):
			child.queue_free()
	
	schedule_next_spawn()


func _process(delta):
	if is_playing:
		current_speed += 15.0 * delta

func schedule_next_spawn():
	if not is_playing: return
	
	var jump_time = (2.0 * abs(bean.JUMP_VELOCITY)) / bean.gravity
	var buffer_time = 0.2
	
	var min_time = jump_time + buffer_time
	var random_extra = randf_range(0.0, 1.5)
	
	timer.wait_time = min_time + random_extra
	timer.start()

func _on_timer_timeout():
	var obs = obstacle_scene.instantiate()
	obs.add_to_group("obstacles")
	obs.speed = current_speed
	obs.position = Vector2(1200, 500)
	add_child(obs)
	
	schedule_next_spawn()

func game_over():
	is_playing = false
	timer.stop()
	
	if active_player and active_player.has_method("_on_yes_button_pressed"):
		active_player._on_yes_button_pressed()
		active_player = null

extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002
const ZOOM_SPEED = 0.5
const MIN_ZOOM = 1.0
const MAX_ZOOM = 5.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var is_right_clicking: bool = false
var is_playing_minigame: bool = false
var current_station = null

@onready var spring_arm = $SpringArm3D
@onready var camera = $SpringArm3D/Camera3D
@onready var interact_ray = $InteractRay
@onready var interact_prompt = $InteractPrompt
@onready var quit_popup = $CanvasLayer/QuitMinigamePopup

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority():
		return

func _input(event):
	if not is_multiplayer_authority():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		is_right_clicking = event.pressed
		if is_right_clicking:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - ZOOM_SPEED, MIN_ZOOM, MAX_ZOOM)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + ZOOM_SPEED, MIN_ZOOM, MAX_ZOOM)

	if event is InputEventMouseMotion and is_right_clicking:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		spring_arm.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/4)

func _process(_delta):
	if not is_multiplayer_authority(): 
		return
	
	if is_playing_minigame:
		interact_prompt.visible = false
		
		if Input.is_action_just_pressed("ui_cancel"):
			quit_popup.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if interact_ray.is_colliding():
		var target = interact_ray.get_collider()
		
		if target.has_method("get_interact_prompt"):
			interact_prompt.text = target.get_interact_prompt()
			interact_prompt.visible = true
			
			if Input.is_physical_key_pressed(KEY_E):
				target.interact(self)
		else:
			interact_prompt.visible = false
	else:
		interact_prompt.visible = false

func _physics_process(delta):
	if not is_multiplayer_authority():
		return

	if is_playing_minigame:
		return 

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _on_yes_button_pressed():
	quit_popup.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	is_playing_minigame = false
	
	global_position += global_transform.basis.z * 1.5 + Vector3(0, 0.2, 0)
	
	$CollisionShape3D.disabled = false
	spring_arm.collision_mask = 1
	
	camera.reparent(spring_arm, false)
	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	
	if current_station:
		current_station.remove_player(self)
		current_station = null

func _on_no_button_pressed():
	quit_popup.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

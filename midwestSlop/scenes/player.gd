extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_right_clicking = false

# --- Camera Settings ---
const MOUSE_SENSITIVITY = 0.003
const MIN_ZOOM = 2.0
const MAX_ZOOM = 12.0
const ZOOM_SPEED = 0.5

@onready var camera = $SpringArm3D/Camera3D
@onready var spring_arm = $SpringArm3D

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	if is_multiplayer_authority():
		camera.current = true
	else:
		camera.current = false

# Notice this is now just _input, NOT _unhandled_input!
func _input(event):
	if not is_multiplayer_authority():
		return

	# Track exactly when the right mouse button goes down or up
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		is_right_clicking = event.pressed
		if is_right_clicking:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Handle Zooming
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - ZOOM_SPEED, MIN_ZOOM, MAX_ZOOM)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + ZOOM_SPEED, MIN_ZOOM, MAX_ZOOM)

	# Handle Camera Rotation
	if event is InputEventMouseMotion and is_right_clicking:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		spring_arm.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/4)

func _physics_process(delta):
	if not is_multiplayer_authority():
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

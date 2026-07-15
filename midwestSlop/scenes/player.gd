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
var is_inventory_open: bool = false
var current_radio = null
var is_media_menu_open: bool = false
var is_notebook_open: bool = false

@onready var media_popup = $CanvasLayer/MediaPopup
@onready var song_list = $CanvasLayer/MediaPopup/ScrollContainer/VBoxContainer
@onready var inventory_popup = $CanvasLayer/InventoryPopup
@onready var notebook_popup = $CanvasLayer/NotebookPopup
@onready var spring_arm = $SpringArm3D
@onready var camera = $SpringArm3D/Camera3D
@onready var interact_ray = $InteractRay
@onready var interact_prompt = $InteractPrompt
@onready var quit_popup = $CanvasLayer/QuitMinigamePopup
@onready var crosshair = $CanvasLayer/Crosshair

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority():
		$CanvasLayer.hide() 
		return
		
	camera.current = true
	inventory_popup.visible = false
	media_popup.visible = false
	notebook_popup.visible = false
	
	# Connect Media UI
	var close_btn = find_child("CloseMediaButton", true, false)
	if close_btn and not close_btn.pressed.is_connected(close_media_menu):
		close_btn.pressed.connect(close_media_menu)
		
	var stop_btn = find_child("StopButton", true, false)
	if stop_btn and not stop_btn.pressed.is_connected(_on_stop_pressed):
		stop_btn.pressed.connect(_on_stop_pressed)
		
	var vol_slider = find_child("VolumeSlider", true, false)
	if vol_slider and not vol_slider.value_changed.is_connected(_on_volume_changed):
		vol_slider.value_changed.connect(_on_volume_changed)
		
	# Connect Notebook UI
	var close_notebook_btn = find_child("CloseNotebookButton", true, false)
	if close_notebook_btn and not close_notebook_btn.pressed.is_connected(close_notebook):
		close_notebook_btn.pressed.connect(close_notebook)

func _input(event):
	if not is_multiplayer_authority():
		return

	# Toggle Media Menu with 'M'
	if event is InputEventKey and event.physical_keycode == KEY_M and event.pressed and not event.echo:
		if is_playing_minigame or is_inventory_open or is_notebook_open:
			return # Don't open if busy
			
		if is_media_menu_open:
			close_media_menu()
		else:
			open_media_menu()

	# Toggle Inventory with 'F'
	if event is InputEventKey and event.physical_keycode == KEY_F and event.pressed and not event.echo:
		if is_playing_minigame or is_media_menu_open or is_notebook_open:
			return
			
		is_inventory_open = !is_inventory_open
		inventory_popup.visible = is_inventory_open
		
		if is_inventory_open:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			if crosshair: crosshair.visible = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if crosshair: crosshair.visible = true

	# Block the camera from moving if ANY menu is open
	if is_inventory_open or is_media_menu_open or is_notebook_open:
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
	
	if is_notebook_open:
		interact_prompt.visible = false
		if Input.is_action_just_pressed("ui_cancel"):
			close_notebook()
		return
	
	if is_media_menu_open:
		interact_prompt.visible = false
		if Input.is_action_just_pressed("ui_cancel"):
			close_media_menu()
		return
	
	if is_playing_minigame:
		interact_prompt.visible = false
		if crosshair:
			crosshair.visible = false
		
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

	# Lock movement if tied up in menus or games
	if is_playing_minigame or is_inventory_open or is_media_menu_open or is_notebook_open:
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

# --- NOTEBOOK FUNCTIONS ---

func open_notebook():
	is_notebook_open = true
	notebook_popup.visible = true
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if crosshair: crosshair.visible = false

func close_notebook():
	is_notebook_open = false
	notebook_popup.visible = false
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if crosshair: crosshair.visible = true


# --- MEDIA MENU FUNCTIONS ---

func open_media_menu(radio_node = null):
	if radio_node:
		current_radio = radio_node
	elif current_radio == null:
		current_radio = get_tree().root.find_child("RadioTV", true, false)
		
	is_media_menu_open = true
	media_popup.visible = true
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if crosshair: crosshair.visible = false
	
	populate_song_list()

func close_media_menu():
	is_media_menu_open = false
	media_popup.visible = false
	current_radio = null
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if crosshair: crosshair.visible = true

func populate_song_list():
	for child in song_list.get_children():
		if child.name != "CloseMediaButton":
			child.queue_free()
			
	var added_songs = []
	
	var dir = DirAccess.open("res://music")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".mp3") or file_name.ends_with(".ogv"):
					var clean_name = file_name.replace(".import", "")
					
					if not added_songs.has(clean_name):
						added_songs.append(clean_name)
						var btn = Button.new()
						btn.text = clean_name
						btn.pressed.connect(_on_song_selected.bind(clean_name))
						song_list.add_child(btn)
			file_name = dir.get_next()

func _on_song_selected(file_name: String):
	if current_radio and current_radio.has_method("play_media"):
		current_radio.play_media("res://music/" + file_name)
	close_media_menu()

func _on_stop_pressed():
	if current_radio and current_radio.has_method("stop_media"):
		current_radio.stop_media()

func _on_volume_changed(value: float):
	if current_radio and current_radio.has_method("set_volume"):
		current_radio.set_volume(value)


# --- MINIGAME EXIT FUNCTIONS ---

func _on_yes_button_pressed():
	quit_popup.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	is_playing_minigame = false
	
	if crosshair:
		crosshair.visible = true 
	
	rotation = Vector3.ZERO
	
	var nudge_distance = 1.5
	if current_station and current_station.player_2 == self:
		nudge_distance = -1.5
		
	global_position += global_transform.basis.z * nudge_distance + Vector3(0, 0.2, 0)
	
	$CollisionShape3D.disabled = false
	spring_arm.collision_mask = 1
	
	if camera.get_parent() != spring_arm:
		camera.reparent(spring_arm, false)
	
	camera.transform = Transform3D()
	
	if current_station:
		if current_station.has_method("remove_player"):
			current_station.remove_player(self)
		current_station = null

func _on_no_button_pressed():
	quit_popup.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
var is_movement_locked: bool = false
var bottle_caps: int = 0
var beer_cooldown_timer: float = 0.0
var base_beer_cooldown: float = 5.0
var cooldown_multiplier: float = 1.0
var notification_id: int = 0

var is_wager_menu_open: bool = false
var proposed_wager: int = 0
var opponent_wager: int = 0
var opponent_peer_id: int = 0
var wager_locked_in: bool = false

var bag_scene = preload("res://cornhole_bag.tscn")

@onready var wager_popup = $CanvasLayer/WagerPopup
@onready var wager_input = $CanvasLayer/WagerPopup/VBoxContainer/WagerInput
@onready var wager_status = $CanvasLayer/WagerPopup/VBoxContainer/StatusLabel
@onready var notification_label = $CanvasLayer/NotificationLabel
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
@onready var caps_label = $CanvasLayer/InventoryPopup/CapsLabel

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
	
	var close_btn = find_child("CloseMediaButton", true, false)
	if close_btn and not close_btn.pressed.is_connected(close_media_menu):
		close_btn.pressed.connect(close_media_menu)
		
	var stop_btn = find_child("StopButton", true, false)
	if stop_btn and not stop_btn.pressed.is_connected(_on_stop_pressed):
		stop_btn.pressed.connect(_on_stop_pressed)
		
	var vol_slider = find_child("VolumeSlider", true, false)
	if vol_slider and not vol_slider.value_changed.is_connected(_on_volume_changed):
		vol_slider.value_changed.connect(_on_volume_changed)
		
	var close_notebook_btn = find_child("CloseNotebookButton", true, false)
	if close_notebook_btn and not close_notebook_btn.pressed.is_connected(close_notebook):
		close_notebook_btn.pressed.connect(close_notebook)
	
	wager_popup.visible = false
	
	var propose_btn = find_child("ProposeButton", true, false)
	if propose_btn and not propose_btn.pressed.is_connected(_on_propose_pressed):
		propose_btn.pressed.connect(_on_propose_pressed)
		
	var accept_btn = find_child("AcceptButton", true, false)
	if accept_btn and not accept_btn.pressed.is_connected(_on_accept_pressed):
		accept_btn.pressed.connect(_on_accept_pressed)
		
	var play_alone_btn = find_child("PlayAloneButton", true, false)
	if play_alone_btn and not play_alone_btn.pressed.is_connected(_on_play_alone_pressed):
		play_alone_btn.pressed.connect(_on_play_alone_pressed)
		
	multiplayer.peer_disconnected.connect(_on_peer_disconnected_wager_check)

func _input(event):
	if not is_multiplayer_authority():
		return

	if event is InputEventKey and event.physical_keycode == KEY_M and event.pressed and not event.echo:
		if is_playing_minigame or is_inventory_open or is_notebook_open:
			return
			
		if is_media_menu_open:
			close_media_menu()
		else:
			open_media_menu()

	if event is InputEventKey and event.physical_keycode == KEY_F and event.pressed and not event.echo:
		if is_playing_minigame or is_media_menu_open or is_notebook_open:
			return
			
		is_inventory_open = !is_inventory_open
		update_caps_display()
		inventory_popup.visible = is_inventory_open
		
		if is_inventory_open:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			if crosshair: crosshair.visible = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if crosshair: crosshair.visible = true

	if event is InputEventKey and event.physical_keycode == KEY_E and event.pressed and not event.echo:
		if is_inventory_open or is_media_menu_open or is_notebook_open:
			return 
			
		if interact_ray.is_colliding():
			var target = interact_ray.get_collider()
			if target.has_method("interact"):
				target.interact(self)
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
	if beer_cooldown_timer > 0:
		beer_cooldown_timer -= _delta
	
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
			crosshair.visible = true
		
		if Input.is_action_just_pressed("ui_cancel"):
			quit_popup.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if interact_ray.is_colliding():
		var target = interact_ray.get_collider()
		
		if target.has_method("get_interact_prompt"):
			var prompt_text = target.get_interact_prompt()
			if prompt_text != "":
				interact_prompt.text = prompt_text
				interact_prompt.visible = true
			else:
				interact_prompt.visible = false
		else:
			interact_prompt.visible = false
	else:
		interact_prompt.visible = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if not is_movement_locked:
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

func _on_yes_button_pressed():
	quit_popup.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	is_playing_minigame = false
	
	wager_popup.visible = false
	is_wager_menu_open = false
	proposed_wager = 0
	opponent_wager = 0
	wager_locked_in = false
	
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

func drink_beer():
	if beer_cooldown_timer <= 0:
		bottle_caps += 1
		beer_cooldown_timer = base_beer_cooldown * cooldown_multiplier
		show_notification("Drank beer! Total Caps: " + str(bottle_caps))
		update_caps_display()
		return true
	else:
		var time_left = int(beer_cooldown_timer)
		show_notification("Why drink 2 at once, party animal?? Cooldown: " + str(time_left) + " seconds remaining")
		return false
		
func _on_play_alone_pressed():
	wager_status.text = "Playing solo!"
	find_child("PlayAloneButton").disabled = true
	
	close_wager_menu()
	
	if current_station and current_station.has_method("start_minigame"):
		current_station.start_minigame()

func update_caps_display():
	if caps_label:
		caps_label.text = "Caps: " + str(bottle_caps)

func show_notification(message: String):
	notification_label.text = message
	notification_label.visible = true
	
	notification_id += 1
	var current_id = notification_id
	
	await get_tree().create_timer(3.0).timeout
	
	if notification_id == current_id:
		notification_label.visible = false

func close_wager_menu():
	is_wager_menu_open = false
	wager_popup.visible = false
	
	if not is_inventory_open and not is_media_menu_open and not is_notebook_open:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if crosshair: crosshair.visible = true
		
func open_wager_menu(target_opponent_id: int):
	opponent_peer_id = target_opponent_id
	is_wager_menu_open = true
	wager_popup.visible = true
	wager_locked_in = false
	
	wager_input.text = ""
	wager_input.editable = true
	wager_status.text = "Waiting for input..."
	find_child("AcceptButton").disabled = true
	find_child("ProposeButton").disabled = false
	
	var play_alone_btn = find_child("PlayAloneButton", true, false)
	if play_alone_btn:
		play_alone_btn.disabled = false
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if crosshair: crosshair.visible = false
	
func _on_propose_pressed():
	var amount = wager_input.text.to_int()
	
	if amount <= 0:
		wager_status.text = "Enter a valid amount!"
		return
	if amount > bottle_caps:
		wager_status.text = "Not enough caps!"
		return
		
	proposed_wager = amount
	wager_input.editable = false
	find_child("ProposeButton").disabled = true
	wager_status.text = "Sent proposal. Waiting for opponent..."
	
	rpc_id(opponent_peer_id, "receive_wager_proposal", amount, multiplayer.get_unique_id())

@rpc("any_peer", "call_remote")
func receive_wager_proposal(amount: int, sender_id: int):
	if sender_id == opponent_peer_id:
		opponent_wager = amount
		wager_status.text = "Opponent bet: " + str(amount) + " caps."
		
		if amount > bottle_caps:
			wager_status.text = "Opponent bet " + str(amount) + ". You are too broke!"
		else:
			find_child("AcceptButton").disabled = false

func _on_accept_pressed():
	find_child("AcceptButton").disabled = true
	wager_status.text = "Wager Accepted! Game starting..."
	
	rpc_id(opponent_peer_id, "receive_wager_acceptance", multiplayer.get_unique_id())
	
	lock_in_escrow()

@rpc("any_peer", "call_remote")
func receive_wager_acceptance(sender_id: int):
	if sender_id == opponent_peer_id:
		wager_status.text = "Opponent accepted! Game starting..."
		lock_in_escrow()

func lock_in_escrow():
	wager_locked_in = true
	
	var final_bet = opponent_wager if opponent_wager > 0 else proposed_wager
	bottle_caps -= final_bet
	update_caps_display()
	
	if current_station and current_station.has_method("set_prize_pool"):
		current_station.set_prize_pool(final_bet * 2)
		
	await get_tree().create_timer(1.5).timeout
	close_wager_menu()
	
	if current_station and current_station.has_method("start_minigame"):
		current_station.start_minigame()

func set_cornhole_mode(active: bool) -> void:
	is_movement_locked = active
	if active:
		velocity = Vector3.ZERO
		
func _on_peer_disconnected_wager_check(id: int):
	if is_wager_menu_open and opponent_peer_id == id:
		wager_status.text = "Opponent fled! Starting solo..."
		find_child("ProposeButton").disabled = true
		find_child("AcceptButton").disabled = true
		
		await get_tree().create_timer(1.5).timeout
		_on_play_alone_pressed()

func spawn_bag():
	var bag = bag_scene.instantiate()
	get_tree().current_scene.add_child(bag)
	

	bag.add_collision_exception_with(self)
	self.add_collision_exception_with(bag)
	
	var forward_dir = -camera.global_transform.basis.z.normalized()
	bag.global_position = camera.global_position + (forward_dir * 1.5) - Vector3(0, 0.3, 0)

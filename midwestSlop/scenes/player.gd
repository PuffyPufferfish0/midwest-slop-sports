extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002
const ZOOM_SPEED = 0.5
const MIN_ZOOM = 1.0
const MAX_ZOOM = 5.0

var selected_deck_buttons: Array[TextureButton] = []
var card_scene = preload("res://card.tscn")
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var pack_cost: int = 1
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
var active_deck: Array[CardData] = []
var is_wager_menu_open: bool = false
var proposed_wager: int = 0
var opponent_wager: int = 0
var opponent_peer_id: int = 0
var wager_locked_in: bool = false
var inventory: Array[CardData] = []
var bag_scene = preload("res://cornhole_bag.tscn")

@onready var cards_grid = $CanvasLayer/InventoryPopup/TabContainer/Cards/ScrollContainer/CardsGrid
@onready var score_ui = $CanvasLayer/ScoreUI
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
@onready var anim_player = $FixedModel/AnimationPlayer
@onready var model = $FixedModel
@onready var deck_popup = $CanvasLayer/DeckSelectionPopup
@onready var deck_grid = $CanvasLayer/DeckSelectionPopup/ScrollContainer/DeckGrid
@onready var confirm_deck_btn = $CanvasLayer/DeckSelectionPopup/ConfirmDeckButton


func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	
func add_card_to_inventory(new_card: CardData):
	inventory.append(new_card)
	print("Added " + new_card.card_name + " to inventory! Total cards: ", inventory.size())
	
func _ready():
	if not is_multiplayer_authority():
		$CanvasLayer.hide() 
		return
	if score_ui: 
		score_ui.visible = false
	deck_popup.visible = false
	
	var confirm_btn = find_child("ConfirmDeckButton", true, false)
	if confirm_btn and not confirm_btn.pressed.is_connected(_on_confirm_deck_pressed):
		confirm_btn.pressed.connect(_on_confirm_deck_pressed)
		
	var my_camera = find_child("Camera3D", true, false)
	if my_camera:
		my_camera.current = is_multiplayer_authority()
		
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
		
	# --- SHOP UI CONNECTIONS ---
	var buy_pack_btn = find_child("BuyPackButton", true, false)
	if buy_pack_btn and not buy_pack_btn.pressed.is_connected(_on_buy_pack_pressed):
		buy_pack_btn.pressed.connect(_on_buy_pack_pressed)
		
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
			update_inventory_ui()
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
			var shape_idx = interact_ray.get_collider_shape()
			
			if target.has_method("interact_with_shape"):
				target.interact_with_shape(self, shape_idx)
			elif target.has_method("interact"):
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
		return

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
	if not is_multiplayer_authority():
		return
		
	if is_movement_locked:
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

	var horizontal_speed = Vector2(velocity.x, velocity.z).length()

	if horizontal_speed > 0.1:
		if anim_player:
			anim_player.play("walk_perfect")
		var target_angle = atan2(velocity.x, velocity.z)
		if model:
			model.rotation.y = lerp_angle(model.rotation.y, target_angle, delta * 10.0)
	else:
		if anim_player:
			anim_player.stop()

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
	populate_song_list()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if crosshair: crosshair.visible = false

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
	is_movement_locked = false
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
	
	var opponent_node = get_parent().get_node_or_null(str(opponent_peer_id))
	if opponent_node:
		opponent_node.rpc_id(opponent_peer_id, "receive_wager_proposal", amount, multiplayer.get_unique_id())

@rpc("any_peer", "call_remote")
func receive_wager_proposal(amount: int, sender_id: int):
	open_wager_menu(sender_id)
	
	opponent_wager = amount
	wager_status.text = "Opponent bet: " + str(amount) + " caps."
	
	wager_input.editable = false
	find_child("ProposeButton").disabled = true
		
	if amount > bottle_caps:
		wager_status.text = "Opponent bet " + str(amount) + ". You are too broke!"
		find_child("AcceptButton").disabled = true
	else:
		find_child("AcceptButton").disabled = false

func _on_accept_pressed():
	find_child("AcceptButton").disabled = true
	wager_status.text = "Wager Accepted! Game starting..."
	
	var opponent_node = get_parent().get_node_or_null(str(opponent_peer_id))
	if opponent_node:
		opponent_node.rpc_id(opponent_peer_id, "receive_wager_acceptance", multiplayer.get_unique_id())
	
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
		if score_ui: score_ui.visible = true
	else:
		if score_ui: score_ui.visible = false
		
func _on_peer_disconnected_wager_check(id: int):
	if is_wager_menu_open and opponent_peer_id == id:
		wager_status.text = "Opponent fled! Starting solo..."
		find_child("ProposeButton").disabled = true
		find_child("AcceptButton").disabled = true
		
		await get_tree().create_timer(1.5).timeout
		_on_play_alone_pressed()

func spawn_bag():
	var cam_pos = camera.global_position
	var forward_dir = -camera.global_transform.basis.z.normalized()
	
	var bag_name = "Bag_" + str(Time.get_ticks_usec())
	
	rpc("receive_bag_spawn", cam_pos, forward_dir, bag_name)

@rpc("any_peer", "call_local")
func receive_bag_spawn(cam_pos: Vector3, forward_dir: Vector3, bag_name: String):
	var bag = bag_scene.instantiate()
	bag.name = bag_name
	bag.thrower = self
	
	get_parent().add_child(bag)
	
	bag.global_position = cam_pos + (forward_dir * 2.5) - Vector3(0, 0.3, 0)

func bag_thrown(bag: Node3D):
	await get_tree().create_timer(3.0).timeout
	
	var points = 0
	if is_instance_valid(bag):
		points = bag.current_points
		
	if current_station and current_station.has_method("register_score"):
		current_station.rpc("register_score", multiplayer.get_unique_id(), points)
	
	if current_station and current_station.has_method("switch_turn"):
		current_station.rpc("switch_turn")

@rpc("any_peer", "call_local")
func update_score_ui(p1_score: int, p2_score: int):
	if score_ui:
		score_ui.text = "Player 1: " + str(p1_score) + " | Player 2: " + str(p2_score)
# --- SHOP & INVENTORY LOGIC ---

func _on_buy_pack_pressed():
	if bottle_caps >= pack_cost:
		# 1. Deduct the caps and update the UI
		bottle_caps -= pack_cost
		update_caps_display()
		
		# 2. Roll 3 random cards
		var pulled_cards = []
		for i in range(3):
			# This assumes you created the CardDatabase Autoload from earlier!
			var random_card = CardDatabase.get_random_card()
			pulled_cards.append(random_card)
			add_card_to_inventory(random_card)
			
		# 3. Show the player what they got using your notification system
		var result_text = "Pack Opened: " + pulled_cards[0].card_name + ", " + pulled_cards[1].card_name + ", " + pulled_cards[2].card_name
		show_notification(result_text)
		print(result_text)
		update_inventory_ui()
	else:
		# Broke!
		show_notification("Not enough caps! You need " + str(pack_cost) + " to buy a pack.")
func update_inventory_ui():
	if not cards_grid: return
	
	# 1. Clear out the old UI elements so we don't duplicate them
	for child in cards_grid.get_children():
		child.queue_free()
		
	# 2. Loop through your actual inventory array
	for card in inventory:
		var card_img = TextureRect.new()
		
		# IMPORTANT: Change "card_texture" to whatever the image variable 
		# is actually named inside your CardData resource script!
		card_img.texture = card.card_texture
		
		# 3. Format the image so it fits neatly in the grid
		card_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card_img.custom_minimum_size = Vector2(80, 120) # Adjust based on your art's aspect ratio
		
		# 4. Add it to the grid
		cards_grid.add_child(card_img)
		
# --- DECK SELECTION LOGIC ---

func open_deck_builder():
	active_deck.clear()
	deck_popup.visible = true
	confirm_deck_btn.disabled = true
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if crosshair: crosshair.visible = false
	
	# Clear old buttons
	for child in deck_grid.get_children():
		child.queue_free()
		
	# Create a clickable button for every card in inventory
	for card in inventory:
		var btn = TextureButton.new()
		
		# IMPORTANT: Use the exact variable name you found in card_data.gd (e.g., card.art)
		btn.texture_normal = card.card_texture
		
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.custom_minimum_size = Vector2(80, 120)
		
		# Connect the click event and pass the specific card and button
		btn.pressed.connect(func(): _on_deck_card_toggled(card, btn))
		deck_grid.add_child(btn)

func _on_deck_card_toggled(card: CardData, btn: TextureButton):
	# Check if this specific BUTTON is already selected
	if selected_deck_buttons.has(btn):
		selected_deck_buttons.erase(btn)
		
		# Safely remove only ONE instance of this card from the active deck
		active_deck.remove_at(active_deck.find(card)) 
		btn.modulate = Color(1, 1, 1, 1) # Return to normal color
	else:
		if active_deck.size() < 3:
			selected_deck_buttons.append(btn)
			active_deck.append(card)
			btn.modulate = Color(0.5, 1, 0.5, 1) # Tint green
			
	if active_deck.size() == 3:
		confirm_deck_btn.disabled = false
		confirm_deck_btn.text = "Spawn Deck!"
	else:
		confirm_deck_btn.disabled = true
		confirm_deck_btn.text = "Choose 3 (" + str(active_deck.size()) + "/3)"
		
func _on_confirm_deck_pressed():
	deck_popup.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if crosshair: crosshair.visible = true
	
	var deck_paths = []
	var deck_names = [] 
	
	for card in active_deck:
		deck_paths.append(card.resource_path)
		var unique_name = "Card_" + str(multiplayer.get_unique_id()) + "_" + str(Time.get_ticks_usec() + randi() % 1000)
		deck_names.append(unique_name)
		
		var inv_index = inventory.find(card)
		if inv_index != -1:
			inventory.remove_at(inv_index)
			
	update_inventory_ui() 
	selected_deck_buttons.clear() 
	
	var my_seat = 1
	var table_path_str = ""
	
	if current_station:
		# Capture the absolute path as a raw string so it never fails over the network!
		table_path_str = str(current_station.get_path())
		
		if current_station.get("player_2") == self:
			my_seat = 2
		
	rpc("sync_spawn_deck", deck_paths, deck_names, my_seat, table_path_str)
	
@rpc("any_peer", "call_local", "reliable")
func sync_spawn_deck(card_paths: Array, card_names: Array, owner_seat_id: int, table_path_str: String):
	# 1. Instantly find the exact table using the foolproof text path
	var station = get_node_or_null(table_path_str)
	
	if not station:
		print("ERROR: Opponent could not find the table at path: ", table_path_str)
		return
		
	# 2. Find the exact physical seat node to guarantee perfectly synced math
	var target_seat = station.get_node_or_null("seat_position_" + str(owner_seat_id))
	if not target_seat:
		print("ERROR: Could not find seat_position_" + str(owner_seat_id))
		return

	for i in range(card_paths.size()):
		var new_card = card_scene.instantiate()
		new_card.name = card_names[i]
		
		var loaded_data = load(card_paths[i])
		new_card.data = loaded_data 
		new_card.owner_seat = owner_seat_id
		
		station.add_child(new_card)
			
		if new_card.has_method("initialize_card"):
			new_card.initialize_card()
			
		# --- BULLETPROOF SYNCHRONIZED MATH ---
		var table_center = station.global_position
		
		# Draw a line from the table center to the exact seat position
		var dir_to_seat = (target_seat.global_position - table_center).normalized()
		dir_to_seat.y = 0 
		
		# Push the cards 0.6 meters from the center toward the seat
		var base_pos = table_center + (dir_to_seat * 0.6)
		base_pos.y = table_center.y + 0.85 
		
		# Calculate "right" based on the seat's transform so spacing is correct
		var right = target_seat.global_transform.basis.x.normalized()
		var spacing = (i - 1) * 0.35 
		
		new_card.global_position = base_pos + (right * spacing)
		
		# The 180-degree flip is preserved so they face the owner
		new_card.global_rotation = Vector3(deg_to_rad(-90), target_seat.global_rotation.y + deg_to_rad(180), 0)
		new_card.scale = Vector3(0.03, 0.03, 0.03)

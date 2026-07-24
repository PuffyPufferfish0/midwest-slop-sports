extends Area3D

@export var data: CardData

# Visual Nodes
@onready var card_art = $blank_card/CardArt
@export var owner_seat: int = 1
@onready var attack_label_bottom = $blank_card/AttackLabelBottom
@onready var health_label_bottom = $blank_card/HealthLabelBottom
@onready var attack_label_top = $blank_card/AttackLabelTop
@onready var health_label_top = $blank_card/HealthLabelTop

var is_dragging: bool = false
var drag_plane_y: float = 0.0
var base_y: float = 0.0
var current_health: int
var current_attack: int

func _ready():
	if data:
		initialize_card()

func initialize_card():
	current_health = data.base_health
	current_attack = data.base_attack
	
	# Update Owner's text (Bottom)
	attack_label_bottom.text = str(current_attack)
	health_label_bottom.text = str(current_health)
	
	# Update Opponent's text (Top)
	attack_label_top.text = str(current_attack)
	health_label_top.text = str(current_health)
	
	if data.card_texture:
		card_art.texture = data.card_texture

# --- SECURITY HELPER ---
func get_local_seat_number() -> int:
	var all_bodies = get_tree().current_scene.find_children("*", "CharacterBody3D", true, false)
	for body in all_bodies:
		if body.has_method("drink_beer") and body.is_multiplayer_authority():
			if body.get("current_station") != null:
				if body.current_station.get("player_2") == body:
					return 2
			return 1 # Default to 1 if they are the authority but not player 2
	return 0 # Not sitting

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var active_cam = get_viewport().get_camera_3d()
		if not active_cam: return
		
		# LEFT CLICK DOWN
		if event.pressed:
			var mouse_pos = get_viewport().get_mouse_position()
			var ray_query = PhysicsRayQueryParameters3D.new()
			ray_query.from = active_cam.project_ray_origin(mouse_pos)
			ray_query.to = ray_query.from + active_cam.project_ray_normal(mouse_pos) * 1000.0
			ray_query.collide_with_areas = true 
			ray_query.collision_mask = 2
			
			var space_state = get_world_3d().direct_space_state
			var result = space_state.intersect_ray(ray_query)
			
			if result and result.collider == self:
				var my_seat = get_local_seat_number()
				
				# ATTACK MODE (Holding Shift)
				if Input.is_key_pressed(KEY_SHIFT):
					# Pass the clicker's seat to the table so the referee can validate the rules!
					get_tree().call_group("card_table", "handle_card_clicked", self, my_seat)
					
				# DRAG MODE (Just Clicking)
				else:
					# --- AUTHORIZATION CHECK ---
					if my_seat != owner_seat:
						print("Access Denied: That is not your card!")
						return # Kills the function here so they can't drag it
					# ---------------------------
					
					is_dragging = true
					drag_plane_y = global_position.y
					global_position.y += 0.1
					rpc("update_drag_position", global_position)
				
		# LEFT CLICK RELEASE
		else:
			if is_dragging:
				is_dragging = false
				_check_snap_points()

func _process(_delta):
	var active_cam = get_viewport().get_camera_3d()
	
	if is_dragging and active_cam:
		var mouse_pos = get_viewport().get_mouse_position()
		var drop_plane = Plane(Vector3.UP, drag_plane_y)
		var ray_origin = active_cam.project_ray_origin(mouse_pos)
		var ray_normal = active_cam.project_ray_normal(mouse_pos)
		
		var intersection = drop_plane.intersects_ray(ray_origin, ray_normal)
		if intersection:
			global_position = Vector3(intersection.x, global_position.y, intersection.z)
			
			# Broadcast our movement to the opponent as we drag!
			rpc("update_drag_position", global_position)

func _check_snap_points():
	# Lower the card back down
	global_position.y = drag_plane_y
	
	var closest_point = null
	var closest_dist = INF
	
	# 1. Target the snap points for whoever owns the card
	var target_group = "seat_1_snaps"
	if owner_seat == 2:
		target_group = "seat_2_snaps"
	
	# 2. Find the closest snap point in the assigned group
	for area in get_overlapping_areas():
		if area.is_in_group(target_group):
			var dist = global_position.distance_to(area.global_position)
			
			if dist < closest_dist:
				closest_dist = dist
				closest_point = area
				
	# 3. Snap and Rotate
	if closest_point:
		# Snap dead-center to the snap point's position, and lift it slightly on the Y-axis!
		# ---> Tweak the "0.05" up or down to get the exact height you want! <---
		global_position = Vector3(closest_point.global_position.x, closest_point.global_position.y + 0.05, closest_point.global_position.z)
		
		# Copy the snap point's rotation, then pivot it 90 degrees to make it horizontal
		global_rotation = closest_point.global_rotation
		global_rotation.y += deg_to_rad(90)
		
		# Update our drag plane so it remembers this new height for the next time we click it
		drag_plane_y = global_position.y
		
	# CRITICAL: Broadcast the final, perfect resting place and rotation to the network!
	rpc("update_snap_state", global_position, global_rotation)

func set_selected(selected: bool):
	if selected:
		# Remember the height and float up 0.2 meters
		base_y = global_position.y
		global_position.y += 0.2
	else:
		# Drop back down to the resting height
		global_position.y = base_y

# --- NETWORK SYNC FUNCTIONS ---
@rpc("any_peer", "call_remote", "unreliable")
func update_drag_position(new_pos: Vector3):
	global_position = new_pos

@rpc("any_peer", "call_remote", "reliable")
func update_snap_state(final_pos: Vector3, final_rot: Vector3):
	global_position = final_pos
	global_rotation = final_rot
	
# --- NETWORK COMBAT FUNCTIONS ---
@rpc("any_peer", "call_local", "reliable")
func sync_take_damage(amount: int):
	current_health -= amount
	
	health_label_bottom.text = str(current_health)
	health_label_top.text = str(current_health)

@rpc("any_peer", "call_local", "reliable")
func sync_destroy():
	var dying_owner = owner_seat
	queue_free()
	
	# Only the client who owned the card needs to check for a wiped board
	var my_seat = get_local_seat_number()
	if dying_owner == my_seat:
		# Wait one frame to ensure the dying card officially leaves the 3D world
		await get_tree().process_frame 
		
		var my_cards_alive = 0
		var all_areas = get_tree().current_scene.find_children("*", "Area3D", true, false)
		
		# Count all remaining cards that belong to this local player
		for c in all_areas:
			if c.has_method("initialize_card") and c.get("owner_seat") == my_seat and not c.is_queued_for_deletion():
				my_cards_alive += 1
				
		print("Card died! Remaining cards for seat ", my_seat, ": ", my_cards_alive)
		
		# If the board is wiped, find the local player node and reopen the menu!
		if my_cards_alive == 0:
			var all_bodies = get_tree().current_scene.find_children("*", "CharacterBody3D", true, false)
			for body in all_bodies:
				if body.has_method("open_deck_builder") and body.is_multiplayer_authority():
					body.open_deck_builder()
					break

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
				# ATTACK MODE (Holding Shift)
				if Input.is_key_pressed(KEY_SHIFT):
					#print("Targeted card: ", data.card_name, " (Health: ", current_health, " | Attack: ", current_attack, ")")
					get_tree().call_group("card_table", "handle_card_clicked", self, multiplayer.get_unique_id())
				# DRAG MODE (Just Clicking)
				else:
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
	
	# 1. Default to seat 1
	var target_group = "seat_1_snaps"
	
	# 2. Bulletproof way to find the local player in the scene tree
	var all_bodies = get_tree().current_scene.find_children("*", "CharacterBody3D", true, false)
	for body in all_bodies:
		# Find the node running player.gd that belongs to THIS client
		if body.has_method("drink_beer") and body.is_multiplayer_authority():
			if body.get("current_station") != null:
				# If this player is registered as player_2 at the station, switch the target group
				if body.current_station.get("player_2") == body:
					target_group = "seat_2_snaps"
			break
	
	# 3. Find the closest snap point in the assigned group
	for area in get_overlapping_areas():
		if area.is_in_group(target_group):
			var dist = global_position.distance_to(area.global_position)
			
			if dist < closest_dist:
				closest_dist = dist
				closest_point = area
				
	# 4. Snap and Rotate
	if closest_point:
		# Snap dead-center to the snap point's position
		global_position = Vector3(closest_point.global_position.x, drag_plane_y, closest_point.global_position.z)
		
		# Copy the snap point's rotation, then pivot it 90 degrees to make it vertical
		global_rotation = closest_point.global_rotation
		global_rotation.y += deg_to_rad(90)
	else:
		# Optional: Drop behavior if outside a valid snap point
		pass
		
	# CRITICAL: Broadcast the final, perfect resting place and rotation to the network!
	rpc("update_snap_state", global_position, global_rotation)

# --- NETWORK SYNC FUNCTIONS ---

# "unreliable" is used for dragging because we are sending it every single frame. 
# If a packet drops, it doesn't matter, the next frame will instantly correct it.
@rpc("any_peer", "call_remote", "unreliable")
func update_drag_position(new_pos: Vector3):
	global_position = new_pos

# "reliable" is used for the snap. We only send this once when the mouse is released,
# so we guarantee the network delivers this exact final position.
@rpc("any_peer", "call_remote", "reliable")
func update_snap_state(final_pos: Vector3, final_rot: Vector3):
	global_position = final_pos
	global_rotation = final_rot
	
# --- NETWORK COMBAT FUNCTIONS ---

@rpc("any_peer", "call_local", "reliable")
func sync_take_damage(amount: int):
	current_health -= amount
	
	# Update both health labels on everyone's screen
	health_label_bottom.text = str(current_health)
	health_label_top.text = str(current_health)

@rpc("any_peer", "call_local", "reliable")
func sync_destroy():
	# Removes the card from the 3D world for everyone
	queue_free()
func set_selected(selected: bool):
	if selected:
		# Remember the height and float up 0.2 meters
		base_y = global_position.y
		global_position.y += 0.2
	else:
		# Drop back down to the resting height
		global_position.y = base_y

extends Area3D

var is_dragging: bool = false
var drag_plane_y: float = 0.0

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
			
			# Tell the ray to look for Area3D nodes
			ray_query.collide_with_areas = true 
			
			# CRITICAL: Tell the raycast to ONLY look at Collision Layer 2!
			# (This mathematically equals 2, ignoring Layer 1 snap points entirely)
			ray_query.collision_mask = 2
			
			var space_state = get_world_3d().direct_space_state
			var result = space_state.intersect_ray(ray_query)
			
			# If the ray hit a card on Layer 2, and it's THIS card
			if result and result.collider == self:
				is_dragging = true
				drag_plane_y = global_position.y
				global_position.y += 0.1
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

func _check_snap_points():
	# Lower the card back down
	global_position.y = drag_plane_y
	
	var closest_point = null
	var closest_dist = INF
	
	for area in get_overlapping_areas():
		# CRITICAL: We check if it belongs to the restricted front group!
		if area.is_in_group("front_snap_points"):
			var dist = global_position.distance_to(area.global_position)
			
			if dist < closest_dist:
				closest_dist = dist
				closest_point = area
				
	if closest_point:
		# Snap dead-center to the snap point's position and rotation
		global_position = Vector3(closest_point.global_position.x, drag_plane_y, closest_point.global_position.z)
		global_rotation = closest_point.global_rotation
	else:
		# Optional: If you drop it outside the valid 3 points, you can make it drop normally or bounce back
		pass

extends Area3D

var is_dragging: bool = false
var drag_plane_y: float = 0.0

@onready var camera: Camera3D = get_viewport().get_camera_3d()

func _ready():
	# Connect the Area3D's built-in click detection
	input_event.connect(_on_input_event)

func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int):
	# Detect left click DOWN directly on the card
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			
			# Lock the Y-height so we drag it smoothly along a flat imaginary table
			drag_plane_y = global_position.y
			
			# Optional: slightly raise the card while dragging so it doesn't clip the table
			global_position.y += 0.1 

func _input(event):
	# We use the global _input to detect the mouse release.
	# This ensures we drop the card even if you move your mouse super fast and the cursor slips off the card model!
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and is_dragging:
			is_dragging = false
			_check_snap_points()

func _process(_delta):
	# While holding the mouse, mathematically drag the card across the table
	if is_dragging and camera:
		var mouse_pos = get_viewport().get_mouse_position()
		
		# Create an invisible flat plane at the card's height
		var drop_plane = Plane(Vector3.UP, drag_plane_y)
		
		# Shoot a ray from the camera through the mouse cursor
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_normal = camera.project_ray_normal(mouse_pos)
		
		# Find exactly where that ray hits the invisible table plane
		var intersection = drop_plane.intersects_ray(ray_origin, ray_normal)
		
		if intersection:
			# Move the card to follow the mouse, keeping the Y height locked
			global_position = Vector3(intersection.x, global_position.y, intersection.z)

func _check_snap_points():
	# Lower the card back down
	global_position.y = drag_plane_y
	
	var closest_point = null
	var closest_dist = 1.5
	
	for area in get_overlapping_areas():
		if area.is_in_group("snap_point"):
			var dist = global_position.distance_to(area.global_position)
			
			if dist < closest_dist:
				closest_dist = dist
				closest_point = area
				
	if closest_point:
		global_position = Vector3(closest_point.global_position.x, drag_plane_y, closest_point.global_position.z)
		
		global_rotation = closest_point.global_rotation

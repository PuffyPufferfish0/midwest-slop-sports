extends Area3D

# Change this to 1 for Player 1's health Area3D, and 2 for Player 2's!
@export var target_seat: int = 1

func get_local_seat_number() -> int:
	var all_bodies = get_tree().current_scene.find_children("*", "CharacterBody3D", true, false)
	for body in all_bodies:
		if body.has_method("drink_beer") and body.is_multiplayer_authority():
			if body.get("current_station") != null:
				if body.current_station.get("player_2") == body:
					return 2
			return 1
	return 0

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.is_key_pressed(KEY_SHIFT):
			var active_cam = get_viewport().get_camera_3d()
			if not active_cam: return
			
			var mouse_pos = get_viewport().get_mouse_position()
			var ray_query = PhysicsRayQueryParameters3D.new()
			ray_query.from = active_cam.project_ray_origin(mouse_pos)
			ray_query.to = ray_query.from + active_cam.project_ray_normal(mouse_pos) * 1000.0
			ray_query.collide_with_areas = true 
			ray_query.collision_mask = 2 # Matches your card layer
			
			var space_state = get_world_3d().direct_space_state
			var result = space_state.intersect_ray(ray_query)
			
			if result and result.collider == self:
				var my_seat = get_local_seat_number()
				get_tree().call_group("card_table", "handle_player_targeted", target_seat, my_seat)

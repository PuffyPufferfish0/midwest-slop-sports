extends RigidBody3D

@export var power_multiplier: float = 0.08
@export var max_pull_distance: float = 300.0
@export var max_power: float = 18.0 

var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var current_drag_pos: Vector2 = Vector2.ZERO
var thrower: Node3D = null
var is_thrown: bool = false
var anchor_position: Vector3 = Vector3.ZERO
var current_points: int = 0

func _ready():
	gravity_scale = 0.0
	freeze = true
	
	contact_monitor = true
	max_contacts_reported = 3
	body_entered.connect(_on_body_entered)
	
	call_deferred("_set_anchor")
func _set_anchor():
	anchor_position = global_position

func _input(event: InputEvent) -> void:
	if is_thrown or thrower == null: return
	
	if thrower.get_multiplayer_authority() != multiplayer.get_unique_id(): return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_start_pos = event.position
			current_drag_pos = event.position
		else:
			if is_dragging:
				is_dragging = false
				_launch_bag()

	elif event is InputEventMouseMotion and is_dragging:
		current_drag_pos = event.position

func _process(_delta: float) -> void:
	if is_dragging and not is_thrown and thrower:
		if thrower.get_multiplayer_authority() == multiplayer.get_unique_id():
			var pull_vector = current_drag_pos - drag_start_pos
			
			if pull_vector.length() > max_pull_distance:
				pull_vector = pull_vector.normalized() * max_pull_distance
				
			var forward_dir = -thrower.camera.global_transform.basis.z.normalized()
			var right_dir = thrower.camera.global_transform.basis.x.normalized()
			var up_dir = Vector3.UP
			
			var visual_offset = (right_dir * (pull_vector.x * 0.003)) + (-forward_dir * (pull_vector.y * 0.004)) + (-up_dir * (pull_vector.y * 0.001))
			
			global_position = anchor_position + visual_offset
			
			rpc("sync_drag_position", global_position)

@rpc("any_peer", "unreliable")
func sync_drag_position(pos: Vector3):
	if thrower and thrower.get_multiplayer_authority() != multiplayer.get_unique_id():
		global_position = pos

func _launch_bag() -> void:
	var pull_vector = current_drag_pos - drag_start_pos
	if thrower and thrower.has_method("bag_thrown"):
		thrower.bag_thrown(self)
	if pull_vector.y <= 20: 
		freeze = false
		gravity_scale = 1.0
		is_thrown = true
		rpc("sync_throw", Vector3.ZERO)
		return
		
	if pull_vector.length() > max_pull_distance:
		pull_vector = pull_vector.normalized() * max_pull_distance

	var forward_dir = -thrower.camera.global_transform.basis.z.normalized()
	var right_dir = thrower.camera.global_transform.basis.x.normalized()
	var up_dir = Vector3.UP
	
	freeze = false
	gravity_scale = 1.0
	is_thrown = true
	
	var throw_speed = pull_vector.length() * power_multiplier
	throw_speed = clamp(throw_speed, 0.0, max_power)
	
	var lateral_aim = -pull_vector.x * 0.004
	var upward_aim = 0.3 + (pull_vector.y * 0.0015) 
	
	var impulse_dir = (forward_dir + (up_dir * upward_aim) + (right_dir * lateral_aim)).normalized()
	var final_impulse = impulse_dir * throw_speed
	
	apply_central_impulse(final_impulse)
	
	if thrower and thrower.has_method("bag_thrown"):
		thrower.bag_thrown(self)
		
	rpc("sync_throw", final_impulse)

@rpc("any_peer", "call_remote")
func sync_throw(impulse: Vector3):
	freeze = false
	gravity_scale = 1.0
	is_thrown = true
	if thrower and thrower.has_method("bag_thrown"):
		thrower.bag_thrown(self)
	if impulse != Vector3.ZERO:
		apply_central_impulse(impulse)
		
	if thrower and thrower.has_method("bag_thrown"):
		thrower.bag_thrown(self)


func get_interact_prompt() -> String:
	if is_thrown:
		return "Press [E] to pick up bag"
	return ""

func interact(player: Node3D) -> void:
	if is_thrown:
		if player.has_method("spawn_bag"):
			player.spawn_bag()
			
		rpc("delete_bag")
		queue_free()

@rpc("any_peer", "call_remote")
func delete_bag():
	queue_free()
	
func _on_body_entered(body: Node):
	if body.is_in_group("board") and current_points < 3:
		current_points = 1

@rpc("any_peer", "call_local")
func score_hole():
	current_points = 3

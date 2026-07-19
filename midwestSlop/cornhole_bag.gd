extends RigidBody3D

@export var throw_power: float = 0.05
@export var curve_multiplier: float = 1.5
@export var hold_distance: float = 1.5

var is_dragging: bool = false
var drag_path: Array[Vector2] = []
var drag_start_time: float = 0.0

var curve_force: float = 0.0
var is_thrown: bool = false

@onready var camera: Camera3D = get_viewport().get_camera_3d()

func _ready():
	gravity_scale = 0.0
	freeze = true 

func _input(event: InputEvent) -> void:
	if is_thrown: return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_path.clear()
			drag_path.append(event.position)
			drag_start_time = Time.get_ticks_msec() / 1000.0
		else:
			if is_dragging:
				is_dragging = false
				_calculate_and_throw(event.position)

	elif event is InputEventMouseMotion and is_dragging:
		drag_path.append(event.position)

func _process(delta: float) -> void:
	if is_dragging and not is_thrown:
		var mouse_pos = get_viewport().get_mouse_position()
		var target_pos = camera.project_position(mouse_pos, hold_distance)
		
		global_position = global_position.lerp(target_pos, 20.0 * delta)

func _calculate_and_throw(end_pos: Vector2) -> void:
	if drag_path.size() < 3: 
		freeze = false
		gravity_scale = 1.0
		is_thrown = true
		return 

	var start_pos: Vector2 = drag_path[0]
	var swipe_vector: Vector2 = end_pos - start_pos
	var swipe_time: float = (Time.get_ticks_msec() / 1000.0) - drag_start_time
	
	if swipe_time <= 0.01: swipe_time = 0.01

	var throw_speed: float = (abs(swipe_vector.y) / swipe_time) * throw_power

	var mid_point: Vector2 = drag_path[drag_path.size() / 2]
	var straight_line_mid: Vector2 = (start_pos + end_pos) / 2.0
	
	var deviation: float = mid_point.x - straight_line_mid.x
	var screen_width: float = get_viewport().get_visible_rect().size.x
	var normalized_curve: float = deviation / (screen_width * 0.5)
	
	curve_force = normalized_curve * curve_multiplier * 15.0 

	var forward_dir: Vector3 = -camera.global_transform.basis.z.normalized()
	var right_dir: Vector3 = camera.global_transform.basis.x.normalized()
	var up_dir: Vector3 = Vector3.UP

	var lateral_aim: float = (end_pos.x - start_pos.x) * 0.01
	
	freeze = false
	gravity_scale = 1.0
	is_thrown = true
	
	var impulse_dir: Vector3 = (forward_dir + (up_dir * 0.5) + (right_dir * lateral_aim)).normalized()
	apply_central_impulse(impulse_dir * throw_speed)

func _physics_process(_delta: float) -> void:
	if is_thrown and linear_velocity.length() > 0.5:
		var right_dir: Vector3 = camera.global_transform.basis.x.normalized()
		apply_central_force(right_dir * curve_force)
# --- INTERACTION SYSTEM ---

func get_interact_prompt() -> String:
	if is_thrown:
		return "Press [E] to pick up bag"
	return ""

func interact(player: Node3D) -> void:
	if is_thrown:
		if player.has_method("spawn_bag"):
			player.spawn_bag()
			
		queue_free()

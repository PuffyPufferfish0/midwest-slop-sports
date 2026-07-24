extends Camera3D
@export var rotation_speed: float = 0.05
func _process(delta: float) -> void:
	rotate_y(rotation_speed * delta)
	

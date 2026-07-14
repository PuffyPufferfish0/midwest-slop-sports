extends Camera3D
# speed of rotation (can be switched)
@export var rotation_speed: float = 0.05
func _process(delta: float) -> void:
	#always rotate about the X axis, to show the house and backyard for shenanigans 
	rotate_y(rotation_speed * delta)
	

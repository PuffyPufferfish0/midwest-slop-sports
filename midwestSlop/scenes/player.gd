extends CharacterBody3D

func _enter_tree():
	#player network ID
	set_multiplayer_authority(name.to_int())

func _physics_process(delta):
	# If this isn't our character, don't let us move it.
	if not is_multiplayer_authority():
		return
		
	# movement
	

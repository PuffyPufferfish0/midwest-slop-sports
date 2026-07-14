extends MeshInstance3D

@export var source_viewport: SubViewport

func _ready():
	await get_tree().process_frame 
	
	if source_viewport:
		var mat = StandardMaterial3D.new()
		
		mat.albedo_texture = source_viewport.get_texture()
		
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED 
		
		material_override = mat
	else:
		print("Projector Screen is missing its Source Viewport!")

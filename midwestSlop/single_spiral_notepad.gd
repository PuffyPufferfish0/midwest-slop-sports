extends StaticBody3D

func get_interact_prompt():
	return "[E] Read Notebook"

func interact(player):
	if player.has_method("open_notebook"):
		player.open_notebook()

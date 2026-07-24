extends StaticBody3D

@onready var minigame = $"../SubViewport/BeanRunMinigame"

func get_interact_prompt():
	return "[E] Play Bean Run"

func interact(player):
	player.is_playing_minigame = true
	
	player.is_movement_locked = true 
	
	player.velocity = Vector3.ZERO
	minigame.start_game(player)

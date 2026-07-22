extends StaticBody3D

func get_interact_prompt():
	return "[E] Drink Beer"

func interact(player):
	if player.has_method("drink_beer"):
		player.drink_beer()

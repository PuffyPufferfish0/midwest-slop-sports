extends StaticBody3D

@export var seat_number: int = 1
@onready var table = get_parent()

func get_interact_prompt():
	if seat_number == 1 and table.player_1 != null:
		return " Seat Taken "
	elif seat_number == 2 and table.player_2 != null:
		return " Seat Taken "
		
	return " 'E' [Join Game] "

func interact(player):
	table.join_game(player, seat_number)

extends Node3D

var player_1_hp: int = 30
var player_2_hp: int = 30

@onready var p1_label = $Player1HealthLabel
@onready var p2_label = $Player2HealthLabel

var selected_attacker: Area3D = null

func handle_card_clicked(clicked_card: Area3D, clicker_seat: int):
	if selected_attacker == null:
		# RULE 1: You can only select YOUR OWN card as an attacker
		if clicked_card.owner_seat == clicker_seat:
			selected_attacker = clicked_card
			selected_attacker.set_selected(true)
			print("Attacker locked in: ", selected_attacker.data.card_name)
		else:
			print("You cannot attack with the opponent's card!")
		
	elif selected_attacker == clicked_card:
		selected_attacker.set_selected(false)
		selected_attacker = null
		print("Attacker deselected.")
		
	else:
		# RULE 2: You can only target the OPPONENT'S card to deal damage
		if clicked_card.owner_seat != clicker_seat:
			print("Target chosen: ", clicked_card.data.card_name)
			resolve_combat(selected_attacker, clicked_card)
			selected_attacker.set_selected(false)
			selected_attacker = null
		else:
			print("Friendly fire is disabled! You cannot attack your own card.")

func resolve_combat(attacker: Area3D, defender: Area3D):
	var damage = attacker.current_attack
	var target_hp = defender.current_health
	var overflow = damage - target_hp
	
	print("Combat resolving! Overflow damage: ", overflow)
	
	if overflow > 0:
		print("Card died! Player ", defender.owner_seat, " takes ", overflow, " damage.")
		# Route the overflow to the defender's owner
		rpc("sync_player_damage", defender.owner_seat, overflow)
		defender.rpc("sync_destroy")
		
	elif overflow == 0:
		print("Perfect kill! No player damage.")
		defender.rpc("sync_destroy")
		
	else:
		print("Card survived!")
		defender.rpc("sync_take_damage", damage)

# --- NETWORK SYNC FOR PLAYER HEALTH ---
@rpc("any_peer", "call_local", "reliable")
func sync_player_damage(seat_id: int, damage: int):
	if seat_id == 1:
		player_1_hp -= damage
		p1_label.text = str(player_1_hp)
	elif seat_id == 2:
		player_2_hp -= damage
		p2_label.text = str(player_2_hp)

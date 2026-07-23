extends Node3D

var player_1_hp: int = 30
var player_2_hp: int = 30

# This holds the card you Shift+Clicked first
var selected_attacker: Area3D = null

# This function gets called whenever a player Shift+Clicks ANY card
func handle_card_clicked(clicked_card: Area3D, clicker_id: int):
	# 1. NO ATTACKER SELECTED YET
	if selected_attacker == null:
		selected_attacker = clicked_card
		selected_attacker.set_selected(true) # Make it float!
		print("Attacker locked in: ", selected_attacker.data.card_name)
		
	# 2. CLICKED THE SAME CARD AGAIN (DESELECT)
	elif selected_attacker == clicked_card:
		selected_attacker.set_selected(false) # Drop it down!
		selected_attacker = null
		print("Attacker deselected.")
		
	# 3. CLICKED A DIFFERENT CARD (ATTACK)
	else:
		print("Target chosen: ", clicked_card.data.card_name)
		resolve_combat(selected_attacker, clicked_card)
		
		# Drop the attacker back down and clear the selection
		selected_attacker.set_selected(false)
		selected_attacker = null

func resolve_combat(attacker: Area3D, defender: Area3D):
	var damage = attacker.current_attack
	var target_hp = defender.current_health
	
	var overflow = damage - target_hp
	
	print("Combat resolving! Overflow damage: ", overflow)
	
	if overflow > 0:
		print("Card died! Player takes ", overflow, " damage.")
		# Tell the network to destroy the card
		defender.rpc("sync_destroy")
		# TODO: Subtract overflow from player HP
		
	elif overflow == 0:
		print("Perfect kill! No player damage.")
		# Tell the network to destroy the card
		defender.rpc("sync_destroy")
		
	else:
		print("Card survived!")
		# Tell the network to apply damage to the card
		defender.rpc("sync_take_damage", damage)

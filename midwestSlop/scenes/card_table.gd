extends Node3D

var player_1_hp: int = 30
var player_2_hp: int = 30

@onready var p1_label = $Player1HealthLabel
@onready var p2_label = $Player2HealthLabel

var selected_attacker: Area3D = null

func handle_card_clicked(clicked_card: Area3D, clicker_seat: int):
	if selected_attacker == null:
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
		rpc("sync_player_damage", defender.owner_seat, overflow)
		defender.rpc("sync_destroy")
		
	elif overflow == 0:
		print("Perfect kill! No player damage.")
		defender.rpc("sync_destroy")
		
	else:
		print("Card survived!")
		defender.rpc("sync_take_damage", damage)

@rpc("any_peer", "call_local", "reliable")
func sync_player_damage(seat_id: int, damage: int):
	if seat_id == 1:
		player_1_hp -= damage
		p1_label.text = str(player_1_hp)
	elif seat_id == 2:
		player_2_hp -= damage
		p2_label.text = str(player_2_hp)
		
	if player_1_hp <= 0 or player_2_hp <= 0:
		var winner_seat = 2 if player_1_hp <= 0 else 1
		trigger_game_over(winner_seat)

func trigger_game_over(winner_seat: int):
	var all_players = get_tree().current_scene.find_children("*", "CharacterBody3D", true, false)
	
	for p in all_players:
		if p.has_method("end_card_game") and p.is_multiplayer_authority():
			# Figure out which seat this local player is in
			var my_seat = 1
			if p.get("current_station") != null and p.current_station.get("player_2") == p:
				my_seat = 2
				
			var did_i_win = (my_seat == winner_seat)
			p.end_card_game(did_i_win)
			
	player_1_hp = 30
	player_2_hp = 30
	p1_label.text = str(30)
	p2_label.text = str(30)
	
func handle_player_targeted(target_seat: int, clicker_seat: int):
	if selected_attacker == null:
		print("Select an attacker first!")
		return
		
	if target_seat == clicker_seat:
		print("You cannot attack yourself!")
		return
		
	var opponent_cards_alive = 0
	var all_areas = get_tree().current_scene.find_children("*", "Area3D", true, false)
	
	for c in all_areas:
		if c.has_method("initialize_card") and c.get("owner_seat") == target_seat and not c.is_queued_for_deletion():
			opponent_cards_alive += 1
			
	if opponent_cards_alive > 0:
		print("Attack Blocked! Opponent still has ", opponent_cards_alive, " cards on the board.")
		return
		
	var damage = selected_attacker.current_attack
	print("Direct Attack! Player ", target_seat, " takes ", damage, " damage.")
	
	selected_attacker.set_selected(false)
	selected_attacker = null
	
	rpc("sync_player_damage", target_seat, damage)
	

extends Node

# This would trigger when you click a "Buy Pack" button or interact with the shop
func buy_booster_pack(buyer_player_node):
	# TODO: Add currency check here later (e.g., if buyer_player_node.coins >= 10)
	
	print("Opening booster pack...")
	
	var pulled_cards = []
	
	# Roll 3 random cards
	for i in range(3):
		var random_card = CardDatabase.get_random_card()
		pulled_cards.append(random_card)
		
		# Send it directly to the player's inventory
		buyer_player_node.add_card_to_inventory(random_card)
		
	# Display the results
	print("Pack contains: ", pulled_cards[0].card_name, ", ", pulled_cards[1].card_name, ", ", pulled_cards[2].card_name)
	

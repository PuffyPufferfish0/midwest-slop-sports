extends Node

func buy_booster_pack(buyer_player_node):
	
	print("Opening booster pack...")
	
	var pulled_cards = []
	
	for i in range(3):
		var random_card = CardDatabase.get_random_card()
		pulled_cards.append(random_card)
		
		buyer_player_node.add_card_to_inventory(random_card)
		
	print("Pack contains: ", pulled_cards[0].card_name, ", ", pulled_cards[1].card_name, ", ", pulled_cards[2].card_name)
	

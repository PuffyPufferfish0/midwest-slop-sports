extends Node

# Drag and drop all your CardData .tres files into this array
var all_cards: Array[CardData] = [
	preload("res://cards/cardMake/res/chillyGnome/chillyGnome.tres"),
	preload("res://cards/cardMake/res/dragon/dragon.tres"),
	preload("res://cards/cardMake/res/fireball/fireball.tres"),
	preload("res://cards/cardMake/res/fish/fish.tres"),
	preload("res://cards/cardMake/res/goblin/goblin.tres"),
	preload("res://cards/cardMake/res/Grillston/Grillston.tres"),
	preload("res://cards/cardMake/res/Ogre/Ogre.tres"),
	preload("res://cards/cardMake/res/ReadyGnome/ReadyGnome.tres"),
	preload("res://cards/cardMake/res/scaredGoblin/scaredGoblin.tres"),
	preload("res://cards/cardMake/res/SleepyGnome/SleepyGnome.tres"),
	preload("res://cards/cardMake/res/snowball/snowball.tres"),
	preload("res://cards/cardMake/res/wizard/wizard.tres")
	
		
]

func get_random_card() -> CardData:
	return all_cards.pick_random()

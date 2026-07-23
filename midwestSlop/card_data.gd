extends Resource
class_name CardData

@export var card_name: String = "New Card"
@export var card_texture: Texture2D
@export var base_attack: int = 1
@export var base_health: int = 1

@export_enum("Common", "Uncommon", "Rare", "Legendary") 
var rarity: String = "Common"

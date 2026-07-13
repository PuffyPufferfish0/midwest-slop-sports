extends Node

const PORT = 8910
const IP_ADDRESS = "127.0.0.1" # Localhost

@onready var host_button = $UI/HostButton
@onready var join_button = $UI/JoinButton
@onready var level = $Level
@onready var spawn_point = $Level/SpawnPoint # Grabs the new Marker3D

var player_scene = preload("res://scenes/player.tscn")

func _ready():
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)

func _on_host_pressed():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(_add_player)
	
	_add_player(multiplayer.get_unique_id())
	$UI.hide()

func _on_join_pressed():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	$UI.hide()

func _add_player(id: int):
	var player = player_scene.instantiate()
	player.name = str(id) 
	level.add_child(player)
	
	player.global_position = spawn_point.global_position

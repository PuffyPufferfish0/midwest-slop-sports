extends Node

const PORT = 8910
const IP_ADDRESS = "127.0.0.1"

@onready var host_button = $MainMenu/CanvasLayer/HostButton
@onready var join_button = $MainMenu/CanvasLayer/JoinButton
@onready var level = $Level
@onready var spawn_point = $Level/SpawnPoint
@onready var menu_music = $MainMenu/CanvasLayer/Node2D/MenuMusic
@onready var cricket_audio = $Level/cricketAudio
@onready var cricket_timer = $Level/CricketTimer

var player_scene = preload("res://scenes/player.tscn")

var is_steam_active: bool = false
var hosted_lobby_id: int = 0

func _ready():
	host_button.pressed.connect(_on_host_local_pressed)
	join_button.pressed.connect(_on_join_local_pressed)

	multiplayer.peer_connected.connect(_on_peer_connected)

	var init_response = Steam.steamInit()
	if init_response:
		print("Steam initialized successfully!")
		is_steam_active = true
		Steam.lobby_created.connect(_on_steam_lobby_created)
		Steam.lobby_joined.connect(_on_steam_lobby_joined)
	else:
		print("Steam failed to initialize. Falling back to Local ENet.")

func _process(_delta):
	if is_steam_active:
		Steam.run_callbacks()


func _on_host_local_pressed():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	
	_add_player(multiplayer.get_unique_id())
	_start_game()

func _on_join_local_pressed():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	
	_start_game()


func host_steam_game():
	if is_steam_active:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 4)

func _on_steam_lobby_created(connect: int, lobby_id: int):
	if connect == 1:
		hosted_lobby_id = lobby_id
		print("Steam Lobby created! ID: ", lobby_id)
		
		Steam.setLobbyData(lobby_id, "name", Steam.getFriendPersonaName(Steam.getSteamID()) + "'s Cornhole Game")
		Steam.setLobbyData(lobby_id, "mode", "cornhole")
		
		var peer = SteamMultiplayerPeer.new()
		peer.create_lobby(lobby_id)
		multiplayer.multiplayer_peer = peer
		
		_add_player(multiplayer.get_unique_id())
		_start_game()

func join_steam_lobby(lobby_id: int):
	if is_steam_active:
		Steam.joinLobby(lobby_id)

func _on_steam_lobby_joined(lobby_id: int, permissions: int, locked: bool, response: int):
	if response == 1:
		print("Successfully joined Steam lobby: ", lobby_id)
		
		var peer = SteamMultiplayerPeer.new()
		peer.connect_lobby(lobby_id)
		multiplayer.multiplayer_peer = peer
		
		_start_game()

func _on_peer_connected(id: int):
	if multiplayer.is_server():
		_add_player(id)

func _add_player(id: int):
	var player = player_scene.instantiate()
	player.name = str(id) 
	level.add_child(player)
	
	player.global_position = spawn_point.global_position
	
func _start_game():
	$MainMenu/CanvasLayer.hide()
	menu_music.stop()
	
	var title_cam = get_node_or_null("MainMenu/Camera3D")
	if title_cam:
		title_cam.current = false
		
	start_next_cricket()


func start_next_cricket():
	var random_time = randf_range(3.0, 30.0)
	
	cricket_timer.start(random_time)

func _on_cricket_timer_timeout():
	cricket_audio.play()
	
	start_next_cricket()

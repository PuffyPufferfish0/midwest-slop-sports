extends Node

signal lobby_created(lobby_id)
signal lobby_joined(lobby_id)
signal lobby_list_updated(lobbies)

var is_steam_active: bool = false
var hosted_lobby_id: int = 0

const DEFAULT_PORT: int = 8080
const LOCAL_IP: String = "127.0.0.1"

func _ready():
	_initialize_steam()

func _initialize_steam():

	var init_response: Dictionary = Steam.steamInit()
	
	if init_response['status'] == 1:
		print("Steam initialized successfully!")
		is_steam_active = true
		
		# Connect Steam Callbacks
		Steam.lobby_created.connect(_on_steam_lobby_created)
		Steam.lobby_joined.connect(_on_steam_lobby_joined)
		Steam.lobby_match_list.connect(_on_steam_lobby_match_list)
	else:
		print("Steam failed to initialize. Falling back to Local ENet.")
		is_steam_active = false

func _process(_delta):
	if is_steam_active:
		Steam.run_callbacks()


func host_game(use_steam: bool):
	if use_steam and is_steam_active:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 4)
	else:
		var peer = ENetMultiplayerPeer.new()
		var error = peer.create_server(DEFAULT_PORT)
		if error == OK:
			multiplayer.multiplayer_peer = peer
			print("Local ENet Server started on port " + str(DEFAULT_PORT))
			get_tree().change_scene_to_file("res://main.tscn")
		else:
			print("Failed to host local server: ", error)

func _on_steam_lobby_created(connect: int, lobby_id: int):
	if connect == 1:
		hosted_lobby_id = lobby_id
		print("Steam Lobby created! ID: ", lobby_id)
		
		Steam.setLobbyData(lobby_id, "name", Steam.getFriendPersonaName(Steam.getSteamID()) + "'s Game")
		Steam.setLobbyData(lobby_id, "mode", "cornhole")
		
		var peer = SteamMultiplayerPeer.new()
		peer.create_lobby(lobby_id)
		multiplayer.multiplayer_peer = peer
		
		lobby_created.emit(lobby_id)
		get_tree().change_scene_to_file("res://main.tscn")


func join_local_game(ip_address: String = LOCAL_IP):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, DEFAULT_PORT)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Joined Local Server at ", ip_address)
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		print("Failed to join local server: ", error)

func join_steam_lobby(lobby_id: int):
	if is_steam_active:
		Steam.joinLobby(lobby_id)

func _on_steam_lobby_joined(lobby_id: int, permissions: int, locked: bool, response: int):
	if response == 1:
		print("Successfully joined Steam lobby: ", lobby_id)
		
		var peer = SteamMultiplayerPeer.new()
		peer.connect_lobby(lobby_id)
		multiplayer.multiplayer_peer = peer
		
		lobby_joined.emit(lobby_id)
		get_tree().change_scene_to_file("res://main.tscn")


func request_steam_lobby_list():
	if is_steam_active:
		Steam.addRequestLobbyListStringFilter("mode", "cornhole", Steam.LOBBY_COMPARISON_EQUAL)
		Steam.requestLobbyList()

func _on_steam_lobby_match_list(lobbies: Array):
	lobby_list_updated.emit(lobbies)

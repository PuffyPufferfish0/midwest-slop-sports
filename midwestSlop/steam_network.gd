#//extends Node //just commented this out for now since the game can't open with all the errors - Aidan
#
#var is_on_steam: bool = false
#var steam_app_id: int = 480
#
#var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()
#var lobby_id: int = 0
#var player_scene = preload("res://scenes/player.tscn")
#
#func _ready():
	#_initialize_steam()
#
	#Steam.lobby_created.connect(_on_lobby_created)
	#Steam.lobby_match_list.connect(_on_lobby_match_list)
	#Steam.lobby_joined.connect(_on_lobby_joined)
	#
	#multiplayer.peer_connected.connect(_on_peer_connected)
	#multiplayer.peer_disconnected.connect(_on_peer_disconnected)
#
#func _process(_delta):
	#if is_on_steam:
		#Steam.run_callbacks()
#
#func _initialize_steam():
	#OS.set_environment("SteamAppId", str(steam_app_id))
	#OS.set_environment("SteamGameId", str(steam_app_id))
	#
	#if Steam.loggedOn():
		#is_on_steam = true
		#print("Already connected! Logged in as: ", Steam.getPersonaName())
		#return
		#
	#var initialize_response: Dictionary = Steam.steamInitEx(false, steam_app_id)
	#print("Steam Init Status: ", initialize_response)
	#
	#if initialize_response['status'] == 0:
		#is_on_steam = true
		#print("Success! Logged in as: ", Steam.getPersonaName())
	#else:
		#print("Failed to initialize Steam. Error code: ", initialize_response['status'])
#
#func host_steam_game():
	#print("Attempting to create Steam Lobby...")
	#Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 2)
#
#func join_steam_game():
	#print("Searching for active match lobbies...")
	#Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	#Steam.requestLobbyList()
#
#func _on_lobby_created(connect_status: int, created_lobby_id: int):
	#if connect_status == 1:
		#lobby_id = created_lobby_id
		#print("Lobby created successfully! ID: ", lobby_id)
		#
		#Steam.setLobbyData(lobby_id, "name", Steam.getPersonaName() + "'s Backyard Match")
		#
		#var error = peer.create_host(0)
		#if error == OK:
			#multiplayer.multiplayer_peer = peer
			#print("Multiplayer peer hosting active via Steam P2P.")
			#spawn_player(multiplayer.get_unique_id())
		#else:
			#print("Failed to create multiplayer host peer. Error: ", error)
#
#func _on_lobby_match_list(lobbies: Array):
	#print("Found ", lobbies.size(), " lobbies available.")
	#if lobbies.size() > 0:
		#var target_lobby = lobbies[0]
		#print("Attempting to join lobby: ", target_lobby)
		#Steam.joinLobby(target_lobby)
	#else:
		#print("No active lobbies found. Make sure the host computer has started the game!")
#
#func _on_lobby_joined(joined_lobby_id: int, _permissions: int, _locked: bool, response: int):
	#if response == 1:
		#lobby_id = joined_lobby_id
		#print("Successfully entered Steam lobby.")
		#
		#var host_steam_id = Steam.getLobbyOwner(lobby_id)
		#
		#var error = peer.create_client(host_steam_id, 0)
		#if error == OK:
			#multiplayer.multiplayer_peer = peer
			#print("Multiplayer peer client connected to host Steam ID: ", host_steam_id)
		#else:
			#print("Failed to establish multiplayer client peer. Error: ", error)
#
#func _on_peer_connected(id: int):
	#print("Player connected via Godot Multiplayer API! Internal network ID: ", id)
	#if multiplayer.is_server():
		#spawn_player(id)
#
#func _on_peer_disconnected(id: int):
	#print("Player disconnected. Internal network ID: ", id)
#
#func spawn_player(peer_id: int):
	#var current_scene = get_tree().current_scene
	#var players_container = current_scene.get_node("Players")
	#
	#if players_container:
		#var player_instance = player_scene.instantiate()
		#player_instance.name = str(peer_id)
		#players_container.add_child(player_instance)
	#else:
		#print("Error: Could not find the 'Players' node!")

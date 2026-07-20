extends Area3D

@export var target_board: Area3D

var player_1: Node3D = null
var player_2: Node3D = null
var current_turn_id: int = 0

func get_interact_prompt() -> String:
	if player_1 != null and player_2 != null:
		return "Station is full"
	return "Press [E] to join game"

func interact(player: Node3D) -> void:
	if player_1 == null:
		player_1 = player
	elif player_2 == null and player != player_1:
		player_2 = player
	else:
		return

	player.global_position = Vector3(global_position.x, player.global_position.y, global_position.z)
	if target_board:
		var look_pos = Vector3(target_board.global_position.x, player.global_position.y, target_board.global_position.z)
		player.look_at(look_pos, Vector3.UP)
	
	player.current_station = self
	player.is_playing_minigame = true
	player.set_cornhole_mode(true)
	
	if player == player_1:
		var opponent_id = 1 
		var peers = multiplayer.get_peers()
		if peers.size() > 0:
			opponent_id = peers[0] 
		player.open_wager_menu(opponent_id)

func start_minigame() -> void:
	if player_1:
		current_turn_id = player_1.get_multiplayer_authority()
		_start_turn()

func _start_turn():
	if player_1 and player_1.get_multiplayer_authority() == current_turn_id:
		if player_1.get_multiplayer_authority() == multiplayer.get_unique_id():
			player_1.spawn_bag()
			
	elif player_2 and player_2.get_multiplayer_authority() == current_turn_id:
		if player_2.get_multiplayer_authority() == multiplayer.get_unique_id():
			player_2.spawn_bag()

@rpc("any_peer", "call_local")
func switch_turn():
	if player_2 == null:
		if player_1:
			current_turn_id = player_1.get_multiplayer_authority()
	else:
		if current_turn_id == player_1.get_multiplayer_authority():
			current_turn_id = player_2.get_multiplayer_authority()
		else:
			current_turn_id = player_1.get_multiplayer_authority()
	
	_start_turn()

func remove_player(player: Node3D) -> void:
	player.set_cornhole_mode(false)
	if player == player_1:
		player_1 = null
	elif player == player_2:
		player_2 = null

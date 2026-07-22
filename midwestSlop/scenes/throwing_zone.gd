extends Area3D

@export var target_board: Area3D
@export var partner_zone: Area3D

var player_1: Node3D = null
var player_2: Node3D = null
var current_turn_id: int = 0
var p1_score: int = 0
var p2_score: int = 0

func get_interact_prompt() -> String:
	if player_1 != null and player_2 != null:
		return "Station is full"
	if partner_zone and partner_zone.player_1 != null and partner_zone.player_2 != null:
		return "Station is full"
	return "Press [E] to join game"

func interact(player: Node3D) -> void:
	interact_with_shape(player, 0)

func interact_with_shape(player: Node3D, shape_idx: int) -> void:
	var active_game_zone = self
	
	if partner_zone and partner_zone.player_1 != null and partner_zone.player_2 == null:
		active_game_zone = partner_zone
		active_game_zone.player_2 = player
	else:
		if player_1 == null:
			player_1 = player
		elif player_2 == null and player != player_1:
			player_2 = player
		else:
			return

	var target_pos = global_position # Fallback to the zone center
	var owner_id = shape_find_owner(shape_idx)
	var clicked_shape_node = shape_owner_get_owner(owner_id)
	
	if clicked_shape_node != null:
		target_pos = clicked_shape_node.global_position
	
	player.global_position = Vector3(target_pos.x, player.global_position.y, target_pos.z)
	
	if target_board:
		var look_pos = Vector3(target_board.global_position.x, player.global_position.y, target_board.global_position.z)
		player.look_at(look_pos, Vector3.UP)
	
	player.current_station = active_game_zone
	player.is_playing_minigame = true
	player.set_cornhole_mode(true)
	
	if active_game_zone == self and player == player_1:
		var opponent_id = 1 
		var peers = multiplayer.get_peers()
		if peers.size() > 0:
			opponent_id = peers[0] 
		player.open_wager_menu(opponent_id)
func start_minigame() -> void:
	if player_1:
		p1_score = 0
		p2_score = 0
		_sync_scores()
		
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
@rpc("any_peer", "call_local")
func register_score(player_id: int, points: int):
	# Add the points to the correct player
	if player_1 and player_1.get_multiplayer_authority() == player_id:
		p1_score += points
	elif player_2 and player_2.get_multiplayer_authority() == player_id:
		p2_score += points
		
	_sync_scores()

func _sync_scores():
	if player_1 and player_1.has_method("update_score_ui"): 
		player_1.rpc("update_score_ui", p1_score, p2_score)
	if player_2 and player_2.has_method("update_score_ui"): 
		player_2.rpc("update_score_ui", p1_score, p2_score)
		
	if partner_zone:
		partner_zone.p1_score = p1_score
		partner_zone.p2_score = p2_score

extends Area3D

var player_2 = null 
var active_player: Node3D = null
func _on_body_entered(_body: Node3D) -> void:
	pass 

func _on_body_exited(_body: Node3D) -> void:
	pass

func get_interact_prompt() -> String:
	if active_player != null:
		return ""
		
	return "Press [E] to play"

func interact(player: Node3D) -> void:
	active_player = player # Store the player
	
	player.global_position = Vector3(global_position.x, player.global_position.y, global_position.z)
	player.current_station = self
	player.is_playing_minigame = true
	player.set_cornhole_mode(true)
	
	var opponent_id = 1 
	var peers = multiplayer.get_peers()
	if peers.size() > 0:
		opponent_id = peers[0] 
		
	player.open_wager_menu(opponent_id)

func start_minigame() -> void:
	if active_player and active_player.has_method("spawn_bag"):
		active_player.spawn_bag()

func remove_player(player: Node3D) -> void:
	player.set_cornhole_mode(false)
	active_player = null

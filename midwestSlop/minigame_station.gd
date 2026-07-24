extends StaticBody3D

@onready var seat_pos_1 = $seat_position_1
@onready var seat_pos_2 = $seat_position_2
@onready var cam_pos_1 = $table_camera_pos_1
@onready var cam_pos_2 = $table_camera_pos_2

var player_1 = null
var player_2 = null


func join_game(player, seat_number):
	var target_seat = null
	var target_cam_pos = null
	
	if seat_number == 1 and player_1 == null:
		target_seat = seat_pos_1
		target_cam_pos = cam_pos_1
		player_1 = player
		print("Player joined as Player 1!")
	elif seat_number == 2 and player_2 == null:
		target_seat = seat_pos_2
		target_cam_pos = cam_pos_2
		player_2 = player
		print("Player joined as Player 2!")
	else:
		return		
	player.global_position = target_seat.global_position
	player.global_rotation = target_seat.global_rotation
	
	player.is_playing_minigame = true
	player.get_node("CollisionShape3D").disabled = true
	player.spring_arm.collision_mask = 0
	
	player.current_station = self 
	
	player.open_deck_builder()
	
	var cam = player.get_node("SpringArm3D/Camera3D")
	cam.reparent(player.get_parent(), true)
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true) 
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE) 
	
	tween.tween_property(cam, "global_position", target_cam_pos.global_position, 1.2)
	tween.tween_property(cam, "global_rotation", target_cam_pos.global_rotation, 1.2)
	player.is_movement_locked = true
	player.velocity = Vector3.ZERO
	
func remove_player(player):
	if player_1 == player:
		player_1 = null
		print("Player 1 left the game.")
	elif player_2 == player:
		player_2 = null
		print("Player 2 left the game.")

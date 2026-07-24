extends Node3D

@onready var audio_player = $AudioStreamPlayer3D
@onready var video_player = $SubViewport/VideoStreamPlayer
@onready var mp3_bg = $SubViewport/ColorRect
@onready var mp3_label = $SubViewport/ColorRect/Label

func get_interact_prompt():
	return "[E] Use Boombox"

func interact(player):
	if player.has_method("open_media_menu"):
		player.open_media_menu(self)

# --- ADDED RPC TAG HERE ---
@rpc("any_peer", "call_local", "reliable")
func play_media(file_path: String):
	audio_player.stop()
	video_player.stop()
	
	var media = load(file_path)
	
	if file_path.ends_with(".mp3"):
		video_player.visible = false
		mp3_bg.visible = true
		
		mp3_label.text = file_path.get_file().replace(".mp3", "")
		
		audio_player.stream = media
		audio_player.play()
		
	elif file_path.ends_with(".ogv"):
		mp3_bg.visible = false
		video_player.visible = true
		
		video_player.stream = media
		video_player.play()

# --- ADDED RPC TAG HERE ---
@rpc("any_peer", "call_local", "reliable")
func stop_media():
	audio_player.stop()
	video_player.stop()
	video_player.visible = false
	mp3_bg.visible = false
	mp3_label.text = ""

# (Left this local so everyone can set their own volume!)
func set_volume(vol_linear: float):
	var db = linear_to_db(vol_linear)
	audio_player.volume_db = db
	video_player.volume_db = db

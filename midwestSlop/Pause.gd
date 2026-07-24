extends Control

func _ready() -> void:
	hide()
	
func _input(event: InputEvent) -> void: 
	if event.is_action_pressed("ui_cancel"): 
		toggle_pause()
		
func toggle_pause() -> void:
	
	get_tree().paused = !get_tree().paused
	visible = get_tree().paused
	
func _on_resume() -> void:
	toggle_pause() 
func _on_pause() -> void: 
	get_tree().quit() 
	
		

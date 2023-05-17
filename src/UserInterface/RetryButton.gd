extends Button

func _on_button_up():
	PlayerData.load_data()
	get_tree().paused = false
	get_tree().reload_current_scene()

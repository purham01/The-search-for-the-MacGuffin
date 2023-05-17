tool
extends Area2D

export(String, FILE) var next_scene_path = ""
onready var scene_tree: = get_tree()
func _get_configuration_warning():
	return "The next scene property can't be empty" if not next_scene_path else ""

func teleport():
#	scene_tree.paused = true
	SceneChanger.change_scene(next_scene_path,1)





func _on_ExitLevel_body_entered(_body):
	teleport()
	PlayerData.save_data()

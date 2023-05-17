tool
extends Button

export(String, FILE) var next_scene_path = ""
onready var scene_tree: = get_tree()

func _on_button_up():
	SceneChanger.change_scene(next_scene_path, 0)
	if scene_tree.get_current_scene().get_name() == "EndScreen" or scene_tree.get_current_scene().get_name() == "MainScreen":
		PlayerData.reset()
		Dialogic.reset_saves()

func _get_configuration_warning():
	return "next_scene_path must be set for the button to work" if next_scene_path == "" else ""

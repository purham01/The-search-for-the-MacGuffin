extends CanvasLayer

signal scene_changed()

onready var anim_player = $AnimationPlayer

func change_scene(path, delay = 0.5):
	yield(get_tree().create_timer(delay), "timeout")
	anim_player.play("fade")
	yield(anim_player,"animation_finished")
	assert(get_tree().change_scene(path) == OK)
	get_tree().paused = false
	anim_player.play_backwards("fade")
	yield(anim_player,"animation_finished")
	emit_signal("scene_changed")

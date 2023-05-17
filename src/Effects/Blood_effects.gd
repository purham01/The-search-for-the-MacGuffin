extends AnimatedSprite

func _on_Blood_animation_finished():
	queue_free()


func _on_Blood_tree_entered():
	var version = randi() % 4
	if version == 0:
		play("version1")
	elif version == 1:
		play("version2")
	elif version == 2:
		play("version3")
	elif version == 3:
		play("version4")

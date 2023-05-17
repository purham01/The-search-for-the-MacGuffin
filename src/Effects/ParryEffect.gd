extends AnimatedSprite



func _on_Node2D_animation_finished():
	queue_free()

func _on_ParryEffect_tree_entered():
	play("default")

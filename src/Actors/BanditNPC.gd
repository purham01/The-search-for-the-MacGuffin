extends "res://src/Actors/Actor.gd"

var active = false
var in_dialogue = false
onready var playernode = get_tree().get_root().find_node("Player",true,false)
func _process(delta):
	if in_dialogue:
		$QuestionMark.visible = false
	else:
		$QuestionMark.visible = active

func _physics_process(delta):
	_velocity.y += gravity *delta
	_velocity.y= move_and_slide(_velocity, FLOOR_NORMAL).y
	
	if position.direction_to(playernode.position).x <0:
		$AnimatedSprite.flip_h = false
	else:
		$AnimatedSprite.flip_h = true

func _on_TalkArea_body_entered(body):
	if body.name =="Player":
		active = true

func _on_TalkArea_body_exited(body):
	if body.name =="Player":
		active = false
		in_dialogue = false

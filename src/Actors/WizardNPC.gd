extends "res://src/Actors/Actor.gd"


onready var anim_player =$AnimationPlayer
onready var anim_player2 =$AnimationPlayer2
var active = false
var in_dialogue = false
onready var playernode = get_tree().get_root().find_node("Player",true,false)

func _process(delta):
	if in_dialogue and !anim_player2.is_playing():
		$Emoticons.visible = false
	else:
		$Emoticons.visible = active
	
	if position.direction_to(playernode.position).x <0:
		$WizardNPCSprite.flip_h = true
		$WizardNPCSprite.offset.x = -15
	else:
		$WizardNPCSprite.flip_h = false
		$WizardNPCSprite.offset.x = 0

func _physics_process(delta):
	_velocity.y += gravity *delta
	_velocity.y= move_and_slide(_velocity, FLOOR_NORMAL).y
	
	if _velocity.x != 0:
		$WizardNPCSprite.play("Run")

func _on_TalkArea_body_entered(body):
	if body.name =="Player":
		active = true
		anim_player2.play("reset_emoticons")

func _on_TalkArea_body_exited(body):
	if body.name =="Player":
		active = false
		in_dialogue = false


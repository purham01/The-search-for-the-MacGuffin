tool
extends RigidBody2D

enum Potion { HEALTH, BATTLE, IRONSKIN }
export(Potion) var type = Potion.HEALTH

func _ready():
	if type == Potion.IRONSKIN:
		$Sprite.play("ironskin")
	elif type == Potion.BATTLE:
		$Sprite.play("battle")
	else:
		$Sprite.play("health")
		
func _process(_delta):
	if Engine.editor_hint:
		if type == Potion.IRONSKIN:
			$Sprite.play("ironskin")
		elif type == Potion.BATTLE:
			$Sprite.play("battle")
		else:
			$Sprite.play("health")


func _on_HitBox_body_entered(body):
	if body.name == "Player":
		body.add_potion(type)
		get_tree().queue_delete(self)

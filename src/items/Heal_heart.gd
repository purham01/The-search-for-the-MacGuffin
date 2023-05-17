extends RigidBody2D

var amount = 20

func _on_HitBox_body_entered(body):
	if "Player" in body.name:
		if PlayerData.health != PlayerData.max_health:
			PlayerData.set_health(PlayerData.health + amount)
			queue_free()


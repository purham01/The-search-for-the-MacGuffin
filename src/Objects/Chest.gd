extends StaticBody2D
var loot_pool = Items.loot


var hp = 3
var rng = RandomNumberGenerator.new()
var x_direction = 0
   
func _ready():
	$AnimatedSprite.play("idle")
	rng.randomize()

func hit():
	if hp != 1:
		$AnimatedSprite.play("hurt")
		hp -= 1
	else:
		$AnimatedSprite.play("open")

func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "hurt":
		$AnimatedSprite.play("idle")
	if $AnimatedSprite.animation == "open":
		spawn_items(Items.loot.potion,3)

func _on_HitBox_area_entered(area):
	if area.is_in_group("Sword"):
		hit()

func spawn_items(item_scene,amount):
	for Number in amount:
		if rng.randf() <= 0.8:
			x_direction = rng.randf_range(-100, 100)
			var item = item_scene.instance()
			if item.name == "Potion":
				item.type = rng.randi() % 3
			get_tree().current_scene.call_deferred("add_child", item)
			item.position = global_position
			item.apply_impulse(Vector2(),Vector2(x_direction,-200))

extends KinematicBody2D

onready var player = get_tree().get_root().find_node("Player",true,false)
onready var _animated_sprite = $AnimatedSprite
export var move_speed = 120
var velocity = Vector2.ZERO

func _ready():
	$AnimationPlayer.play("Float")

func _physics_process(delta):
	if position.direction_to(player.position).x < 0:
		_animated_sprite.flip_h = true
	else:
		_animated_sprite.flip_h = false
	if position.distance_to(Vector2(player.position.x, position.y)) < 28:
		velocity.x = lerp(velocity.x, 0, 0.3)
	else:
#		velocity = position.direction_to(player.position) * move_speed
		velocity.x = lerp(velocity.x, position.direction_to(player.position).x * move_speed, 0.3)
	if position.distance_to(player.pet_location.global_position) < 1:
		velocity.y = 0
	else:
		velocity.y = lerp(velocity.y,position.direction_to(player.pet_location.global_position).y * move_speed,0.2)
	velocity = move_and_slide(velocity)


func _on_SpritePet_ready():
	_animated_sprite.play("appear")


func _on_AnimatedSprite_animation_finished():
	if _animated_sprite.animation == "appear":
		_animated_sprite.play("default")

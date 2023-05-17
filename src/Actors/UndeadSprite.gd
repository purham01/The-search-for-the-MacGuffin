extends Area2D

export var speed = 350
export var steer_force = 50.0
export var knockback_strenght_x = 2 *Globals.UNIT_SIZE
export var knockback_strenght_y = 5 * Globals.UNIT_SIZE
export var _damage = 20
var minDamage
var maxDamage
var rng = RandomNumberGenerator.new()

var velocity = Vector2.ZERO
var acceleration = Vector2.ZERO
var target = null

var charge = false

onready var _animated_sprite = $AnimatedSprite
onready var charge_timer = $ChargeTimer
onready var playernode = get_tree().get_root().find_node("Player",true,false)


func _ready():
	if get_parent().get_parent().get_parent().ultimate:
		_damage *=2
	minDamage = round(_damage*0.85)
	maxDamage = round(_damage*1.15)
	randomize()


func _on_Sprite_ready():
	_animated_sprite.play("appear")
	start(position, playernode)
	
	
func _physics_process(delta):
	if charge:
		acceleration += seek()
		velocity += acceleration * delta
		velocity = velocity.clamped(speed)
		position += velocity * delta

func _on_AnimatedSprite_animation_finished():
	if _animated_sprite.animation == "appear":
		charge_timer.start()
		$CollisionShape2D.set_deferred("disabled", false)
		_animated_sprite.play("default")
	if _animated_sprite.animation == "die":
		queue_free()

func start(_position, _target):
	position = _position
	target = _target

func seek():
	var steer = Vector2.ZERO
	if target:
		var desired = (target.global_position - global_position).normalized() * speed
		steer = (desired - velocity).normalized() * steer_force
	return steer

func _on_ChargeTimer_timeout():
	var old_position = global_position
	var scene = get_tree().current_scene
	get_parent().remove_child(self)
	scene.call_deferred("add_child", self)
	scale = Vector2(1.5,1.5)
	global_position = old_position
	charge = true


func _on_Sprite_area_entered(area):
	if area.is_in_group("Player_hitbox"):
		var target = area.get_parent()
		var knockback_direction = (target.global_position - global_position).normalized()
		var knockback_x = sign(knockback_direction.x) * knockback_strenght_x
		var knockback_y = sign(knockback_direction.y) * knockback_strenght_y
		var damage_dealt = rng.randi_range(minDamage, maxDamage)
		
		target.damage(damage_dealt, knockback_x, -knockback_strenght_y)
		die()

func die():
	$CollisionShape2D.set_deferred("disabled", true)
	set_physics_process(false)
	_animated_sprite.play("die")
	
func _on_Sprite_body_entered(body):
	if body.name =="Player":
		var knockback_direction = (body.global_position - global_position).normalized()
		var knockback_x = sign(knockback_direction.x) * knockback_strenght_x
		var knockback_y = sign(knockback_direction.y) * knockback_strenght_y
		var damage_dealt = rng.randi_range(minDamage, maxDamage)
		
		body.damage(damage_dealt, knockback_x, -knockback_strenght_y)
		die()
	else:
		die()





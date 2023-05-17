extends KinematicBody2D
class_name Actor

# warning-ignore:unused_signal
signal health_updated(health)
# warning-ignore:unused_signal
signal killed()
# warning-ignore:unused_signal
signal hurt()
# warning-ignore:unused_signal
signal on_hit_enemy()

var FLOOR_NORMAL = Vector2.UP

var rng = RandomNumberGenerator.new()


export var knockback_strenght_x= 2 * Globals.UNIT_SIZE
export var knockback_strenght_y= 5 * Globals.UNIT_SIZE


export var move_speed = 9.5 * Globals.UNIT_SIZE
var max_jump_velocity
var min_jump_velocity
var max_jump_height = 4.25 * Globals.UNIT_SIZE
var min_jump_height = 0.5 * Globals.UNIT_SIZE
var jump_duration = 0.45
var gravity

var _velocity:= Vector2.ZERO

func _ready():
	gravity = 2 * max_jump_height / pow(jump_duration,2)
	max_jump_velocity = - sqrt(2* gravity * max_jump_height)
	min_jump_velocity = - sqrt(2* gravity * min_jump_height)

	rng.randomize()



func damage(_amount, _knockback_x, _knockback_y):
	pass

func knockback(strenght_x, strenght_y):
	_velocity = Vector2(strenght_x, strenght_y)


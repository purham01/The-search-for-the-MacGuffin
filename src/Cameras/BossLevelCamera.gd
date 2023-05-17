extends Camera2D

var player

var goneLeft =false
# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_parent()


func _physics_process(delta):
	
	if player.global_position.x > 1616:
		limit_right = 2192
		
		limit_left = 1616
		limit_top = 40
		zoom.x = 0.9
		zoom.y = 0.9
#	elif player.global_position.x > 0 and goneLeft:
#		position.x = 360
#		zoom.x = 1
#		zoom.y = 1
#		yield(get_tree().create_timer(.2), "timeout")
#
#		goneLeft = false
	else:
		zoom.x = 1
		zoom.y = 1
		limit_left = 0
		limit_right = 1616
		limit_top = 0

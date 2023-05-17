extends Camera2D

var player

var goneLeft =false
# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_parent()


func _physics_process(delta):
	if player.global_position.x < 0:
		position.x =-320
		limit_left =- 480
		goneLeft = true
		zoom.x = 0.75
		zoom.y = 0.75
	elif player.global_position.x > 0 and goneLeft:
		position.x = 360
		zoom.x = 1
		zoom.y = 1
		yield(get_tree().create_timer(.2), "timeout")

		goneLeft = false
	else:
		position.x = 0
		limit_left = 0

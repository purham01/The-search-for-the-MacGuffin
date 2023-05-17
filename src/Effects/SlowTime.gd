extends Node

const END_VALUE = 1

var is_active = false
var time_start
var duration_ms
var start_value

func _ready():
	Engine.time_scale = 1
	
func start(duration = 0.4, strenght = 0.9):
	time_start = OS.get_ticks_msec()
	duration_ms = duration*1000
	start_value = 1 - strenght
	Engine.time_scale = start_value
	is_active = true

func _process(delta):
	if is_active:
		var current_time = OS.get_ticks_msec() - time_start
		var value = circl_ease_in(current_time, start_value, END_VALUE, duration_ms)
		if current_time >= duration_ms:
			is_active = false
			value = END_VALUE
		Engine.time_scale = value


func circl_ease_in(t,b,c,d):
	t/=d
	return -c * (sqrt(1-t*t)-1)+b


func _on_Player_hurt():
	start()
	get_tree().paused=false


func _on_Player_on_hit_enemy():
	start(0.2, 0.8)

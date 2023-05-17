extends Control

const FLASH_RATE = 0.05
const N_FLASHES = 4

onready var health_over = $HealthOver
onready var health_under = $HealthUnder
onready var update_tween = $UpdateTween
onready var pulse_tween = $PulseTween
onready var flash_tween = $FlashTween
onready var tween_delay_timer = $DelayUntilTween
onready var start_up_tween = $StartUpTween
onready var enemynode = get_tree().get_root().find_node("Undead Executioner",true,false)

export (Color) var healthy_color = Color.green
export (Color) var caution_color = Color.yellow
export (Color) var danger_color = Color.red
export (Color) var pulse_color = Color.darkred
export (Color) var flash_color = Color.orange
export (float,0,1,0.05) var caution_zone = 0.5
export (float,0,1,0.05) var danger_zone = 0.2
export (bool) var will_pulse = false

func _ready():
	if enemynode:
		enemynode.connect("set_max_health",self,"set_health")
		enemynode.connect("health_updated",self,"_on_health_updated")
		enemynode.connect("start_fight",self,"fill_hp_bar")

func set_health(max_health):
		var enemy_max_health = max_health
		health_over.max_value = enemy_max_health
		health_under.max_value = enemy_max_health
#		health_over.value = health_over.max_value
#		health_under.value = health_under.max_value

func fill_hp_bar():
	start_up_tween.interpolate_property(health_over, "value", 0, health_over.max_value, 1.5, Tween.TRANS_SINE, Tween.EASE_OUT, 0.4)
#	$StartUpTween.interpolate_property(health_under, "value", 0, health_under.max_value, 3, Tween.TRANS_SINE, Tween.EASE_OUT, 0.4)
	start_up_tween.start()

func _on_health_updated(health):
	health_over.value = health
	tween_delay_timer.start()
	_assign_color(health)
	_flash_damage()

func _assign_color(health):
	if health == 0:
		pulse_tween.set_active(false)
	if health < (health_over.max_value *danger_zone):
		if will_pulse:
			if !pulse_tween.is_active():
				pulse_tween.interpolate_property(health_over, "tint_progress", pulse_color, danger_color, 1.2, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
				pulse_tween.start()
		else:
			health_over.tint_progress = danger_color
	else:
		pulse_tween.set_active(false)
		if health < (health_over.max_value * caution_zone):
			health_over.tint_progress = caution_color
		else:
			health_over.tint_progress = healthy_color

func _flash_damage():
	for i in range(N_FLASHES*2):
		var color = health_over.tint_progress if i % 2 == 1 else flash_color
		var time = FLASH_RATE *i + FLASH_RATE
		flash_tween.interpolate_callback(health_over, time, "set", "tint_progress", color)
	flash_tween.start()

func _on_DelayUntilTween_timeout():
	update_tween.interpolate_property(health_under, "value", health_under.value, health_over.value, 0.6, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.4)
	update_tween.start()


func _on_StartUpTween_tween_completed(object, key):
	health_under.value = health_under.max_value

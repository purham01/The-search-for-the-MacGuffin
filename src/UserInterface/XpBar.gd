extends Control

signal player_level_up
const FLASH_RATE = 0.05
const N_FLASHES = 4

onready var update_tween = $UpdateTween
onready var update_timer = $UpdateTimer
onready var xp_bar = $XpProgressBar
onready var leveledUpTween = $LeveledUpTween
onready var playernode = get_tree().get_root().find_node("Player",true,false)
var new_max_value = []
var level_up_counter = 0

func _ready():
	playernode.connect("exit_combat",self,"_update_bar")
	PlayerData.connect("level_up",self,"level_up_counting")
	var xp_bar_max_value = PlayerData.xp_next_level
	var xp_bar_value = PlayerData.xp
	xp_bar.max_value = xp_bar_max_value
	xp_bar.value = xp_bar_value

func level_up_counting():
	level_up_counter +=1
	new_max_value.insert(new_max_value.size(),PlayerData.xp_next_level)

func _update_bar():
	if xp_bar.max_value < PlayerData.xp_next_level:
		for Number in level_up_counter:
			print(Number)
			level_up_counter -= 1
			leveledUpTween.interpolate_property(xp_bar, "value", xp_bar.value, xp_bar.max_value, 2, Tween.TRANS_SINE, Tween.EASE_IN, 0.4)
			leveledUpTween.start()
			yield(leveledUpTween,"tween_completed")
			xp_bar.max_value = new_max_value[Number]
			xp_bar.value = 0
		update_tween.interpolate_property(xp_bar, "value", xp_bar.value, PlayerData.xp, 2, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	else:
		update_tween.interpolate_property(xp_bar, "value", xp_bar.value, PlayerData.xp, 2, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.4)
		update_tween.start()

func _on_LeveledUpTween_tween_completed(object, key):
	emit_signal("player_level_up")
	if level_up_counter == 0:
		update_tween.start()

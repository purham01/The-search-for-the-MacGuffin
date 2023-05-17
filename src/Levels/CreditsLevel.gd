extends Node2D

onready var player = $Player
onready var tween = $Tween
onready var thank_you = $Control/ThankYou
onready var made_by = $Control/MadeBy
onready var assets1 = $Control/Assets1
onready var assets2 = $Control/Assets2
var bonus_height = Globals.UNIT_SIZE *3

func _ready():
#	player.max_jump_height = Globals.UNIT_SIZE *5
	player.jump_duration = 0.8
	player.gravity = 2 * player.max_jump_height / pow(player.jump_duration,2)
	player.max_jump_velocity = - sqrt(2* player.gravity * player.max_jump_height)
	player.min_jump_velocity = - sqrt(2* player.gravity * player.min_jump_height)
	player.max_jump_velocity = -sqrt(2 * player.gravity * (player.max_jump_height+ bonus_height))

func play_music():
	SoundManager.play_bgm("EndingMusic")

func start_tween():
	var tween_duration = 1
	tween.interpolate_property(
		thank_you, "percent_visible", 0, 1, thank_you.text.length()/10,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween.start()
	yield(tween,"tween_completed")
	tween.interpolate_property(
		 made_by, "percent_visible", 0, 1, made_by.text.length()/3,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween.start()
	yield(tween,"tween_completed")
	tween.interpolate_property(
		assets1, "percent_visible", 0, 1, assets1.text.length()/15,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween.start()
	yield(tween,"tween_completed")
	tween.interpolate_property(
		assets2, "percent_visible", 0, 1,assets2.text.length()/15,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween.start()
	
	
func _on_ExitLevel_body_entered(body):
	$Player._anim_player.play("Exit_level")

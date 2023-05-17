extends Node2D

onready var UI = $UILayer/UserInterface
onready var UI_boss_name = $UILayer/UserInterface/BossHPBar/Label
signal dialogue_ended()
signal dialogue_started()
onready var boss = $"Undead Executioner"

func _ready():
	print($BossMusic.get_stream())
	if float(Dialogic.get_variable("ultimate_boss")) == 1:
		UI_boss_name.set_text(tr("KEY_ULTIMATE_EXECUTIONER"))
		var file = File.new()
		file.open("res://assets/Sounds/music/DavidKBD - Reckless Punk-Metal Pack - 02 - Keep Away or Die.ogg",File.READ)
		var buffer = file.get_buffer(file.get_len())
		var stream = AudioStreamOGGVorbis.new()
		stream.data = buffer
		stream.loop = true
		$BossMusic.set_stream(stream)
		file.close()
	if float(Dialogic.get_variable("boss_fight_started")) == 1:
		$CutsceneArea/CollisionShape2D.set_deferred("disabled",true)
		$LightBandit.queue_free()
		$AnimationPlayer.play("ON_REPLAY")
	else:
		$AnimationPlayer.play("START")


func _on_Player_killed():
	$BossMusic.stop()


func _on_Undead_Executioner_killed():
	$World/Boundary/CollisionShape2D.set_deferred("disabled",true)


func _on_CutsceneArea_body_entered(body):
	$CutsceneArea/CollisionShape2D.set_deferred("disabled",true)
	$AnimationPlayer.play("IntroBossCutscene")
	Dialogic.set_variable("boss_fight_started",1)

func create_new_dialogue(timeline, NPC):
	var new_dialogue = Dialogic.start(timeline, false)
	NPC.in_dialogue = true
	new_dialogue.connect("timeline_end",self,"after_dialogue")
	new_dialogue.connect("timeline_start",self,"enter_dialogue")
	new_dialogue.connect("dialogic_signal", self, 'dialogic_signal')
	UI.dialogue_box.add_child(new_dialogue)

func enter_dialogue(_current_scene):
	emit_signal("dialogue_started")

func after_dialogue(_current_scene):
	emit_signal("dialogue_ended")

func _on_Player_start_dialogue(NPC):
	if get_node_or_null("DialogNode") == null:
		if NPC.name == "WizardNPC":
			create_new_dialogue(tr("KEY_WIZARD_AFTER_BOSS"), NPC)
		elif NPC.name == "BanditNPC":
			create_new_dialogue(tr("KEY_BANDIT_DIALOGUE"), NPC)

func dialogic_signal(value):
	if value == "laugh":
		$WizardNPC.anim_player2.play("laugh")
	if value == "reset_level":
		PlayerData.save_data()
		Dialogic.set_variable("boss_fight_started", 0)
		get_tree().reload_current_scene()


func _on_Player_ready():
	$Player._anim_player.play("Exit_level")


func _on_ExitLevel_body_entered(body):
	if $VictoryMusic.is_playing():
		$Tween.interpolate_property($VictoryMusic,"volume_db",$VictoryMusic.volume_db, -50,1)
	elif $LevelMusic.is_playing(): 
		$Tween.interpolate_property($LevelMusic,"volume_db",$LevelMusic.volume_db, -50,1)
	$Tween.start()
	$Player._anim_player.play("Exit_level")



func _on_VictoryMusic_finished():
	$LevelMusic.play()

extends Node2D

onready var wizard = $WizardNPC
onready var player = $Player
onready var UI = $UICanvasLayer/UserInterface
var wizard_pos = 0
var new_dialogue
signal dialogue_ended()
signal dialogue_started()

func _ready():
#	$Tween.interpolate_property($LevelMusic,"volume_db",$LevelMusic.volume_db, -16, 1.5)
#	$Tween.start()
	if float(Dialogic.get_variable("ended_tutorial")) == 1:
		$WizardTeleportArea0/CollisionShape2D.disabled = true
		$WizardTeleportArea1/CollisionShape2D.disabled = true
		$WizardTeleportArea2/CollisionShape2D.disabled = true
	else:
		$WizardTeleportArea0/CollisionShape2D.disabled = false
		$WizardTeleportArea1/CollisionShape2D.disabled = false
		$WizardTeleportArea2/CollisionShape2D.disabled = false
		
	print("Disabled tutorial: "+ Dialogic.get_variable("ended_tutorial"))
	print("Talked to wizard on position 0: " + Dialogic.get_variable("WizardPosition0"))
	print("Talked to wizard on position 1: " + Dialogic.get_variable("WizardPosition1"))
	print("Talked to wizard on position 2: "+ Dialogic.get_variable("WizardPosition2"))
	yield(get_tree().create_timer(0.5), "timeout")
	if float(Dialogic.get_variable("WizardPosition0")) == 0:
		create_new_dialogue(tr("KEY_LEVELSTART"), wizard)

func dialogic_signal(value):
	if value == "tutorial_changed":
		if float(Dialogic.get_variable("ended_tutorial")) == 1:
			$WizardTeleportArea0/CollisionShape2D.disabled = true
			$WizardTeleportArea1/CollisionShape2D.disabled = true
			$WizardTeleportArea2/CollisionShape2D.disabled = true
		else:
			$WizardTeleportArea0/CollisionShape2D.disabled = false
			$WizardTeleportArea1/CollisionShape2D.disabled = false
			$WizardTeleportArea2/CollisionShape2D.disabled = false

func _on_WizardTeleportArea0_body_entered(body):
	if "Player" in body.name and wizard_pos != 0 and !player.inCombat:
		wizard.anim_player.play("fade")
		yield(wizard.anim_player,"animation_finished")
		wizard.position = $WizardTeleportArea0.position
		wizard.anim_player.play_backwards("fade")
		wizard_pos = 0
		yield(wizard.anim_player,"animation_finished")

func _on_WizardTeleportArea1_body_entered(body):
	if !player.inCombat:
		if float(Dialogic.get_variable("WizardPosition1")) == 0:
			create_new_dialogue(tr("KEY_NOTICE_BANDIT"),wizard)
		if "Player" in body.name and wizard_pos != 1:
			wizard.anim_player.play("fade")
			yield(wizard.anim_player,"animation_finished")
			wizard.position = $WizardTeleportArea1.position
			wizard.anim_player.play_backwards("fade")
			wizard_pos = 1
			yield(wizard.anim_player,"animation_finished")


func _on_WizardTeleportArea2_body_entered(body):
	if !player.inCombat:
		if float(Dialogic.get_variable("WizardPosition2")) == 0:
			create_new_dialogue(tr("KEY_WALL_JUMP"),wizard)
		if "Player" in body.name and wizard_pos != 2:
			wizard.anim_player.play("fade")
			yield(wizard.anim_player,"animation_finished")
			wizard.position = $WizardTeleportArea2.position
			wizard.anim_player.play_backwards("fade")
			wizard_pos = 2
			yield(wizard.anim_player,"animation_finished")

func enter_dialogue(_current_scene):
	emit_signal("dialogue_started")

func after_dialogue(_current_scene):
	emit_signal("dialogue_ended")

func create_new_dialogue(timeline, NPC):
	new_dialogue = Dialogic.start(timeline, false)
	NPC.in_dialogue = true
	new_dialogue.connect("timeline_end",self,"after_dialogue")
	new_dialogue.connect("timeline_start",self,"enter_dialogue")
	new_dialogue.connect("dialogic_signal", self, 'dialogic_signal')
	UI.dialogue_box.add_child(new_dialogue)

func _on_Player_start_dialogue(NPC):
	if wizard_pos==1 and NPC.name == "WizardNPC":
		create_new_dialogue(tr("KEY_TALK_AGAIN_POS1"),NPC)
	elif wizard_pos==2:
		create_new_dialogue(tr("KEY_WALL_JUMP"), NPC)
	else:
		create_new_dialogue(tr("KEY_TALK_AGAIN"), NPC)

func _on_Player_killed():
	#$LevelMusicPlayer.stop()
	pass


func _on_ExitLevel_body_entered(body):
	if $LevelMusic.is_playing(): 
		$Tween.interpolate_property($LevelMusic,"volume_db",$LevelMusic.volume_db, -40, 1)
	$Tween.start()
	player._anim_player.play("Exit_level")

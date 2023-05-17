extends Control

onready var scene_tree: = get_tree()
onready var health_potions: Label = get_node("Potions/VBoxContainer/HealthPotions/Label")
onready var battle_potions: Label = get_node("Potions/VBoxContainer/BattlePotions/Label")
onready var ironskin_potions: Label = get_node("Potions/VBoxContainer/IronskinPotions/Label")
onready var pause_overlay: ColorRect = get_node("PauseOverlay")
onready var pause_title: Label = get_node("PauseOverlay/Title")
onready var dialogue_box = $DialogueBox
onready var _level_up_sprite = $HpBarComplete/LevelSprite
onready var boss_hp_bar = $BossHPBar
onready var tween = $Tween
var paused: = false setget set_paused



func _ready():
	PlayerData.connect("player_died",self,"on_PlayerData_player_died")
	PlayerData.connect("updated_potions",self,"update_interface")
	print(PlayerData.level)
	if PlayerData.level == 1:
		_level_up_sprite.play("Level1")
	elif PlayerData.level == 2:
		_level_up_sprite.play("Level2")
	elif PlayerData.level == 3:
		_level_up_sprite.play("Level3")
	elif PlayerData.level == 4:
		_level_up_sprite.play("Level4")
	elif PlayerData.level == 5:
		_level_up_sprite.play("Level5")
	update_interface()

func start_boss_fight():
	var tween_duration = 1
	tween.interpolate_property(
		$BossHPBar,"modulate", Color(modulate.r, modulate.g, modulate.b, 0.0), 
		Color(modulate.r, modulate.g, modulate.b, modulate.a),
		tween_duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween.interpolate_property(
		$BossHPBar/Label, "percent_visible", 0, 1, tween_duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween.start()
#	yield($Tween,"tween_completed")
#	$Tween.interpolate_property(
#		$BossHPBar/Label, "percent_visible", 0, 1, tween_duration,
#		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
#	)
#	$Tween.start()
	

func on_PlayerData_player_died():
	self.paused = true
	pause_title.set_text(tr("KEY_DEATH_MESSAGE"))

func play_level_up_animation():
	if _level_up_sprite.animation == "Level1":
		_level_up_sprite.play("LVL2LevelUp")
	elif _level_up_sprite.animation == "Level2":
		_level_up_sprite.play("LVL3LevelUp")
	elif _level_up_sprite.animation == "Level3":
		_level_up_sprite.play("LVL4LevelUp")
	elif _level_up_sprite.animation == "Level4":
		_level_up_sprite.play("LVL5LevelUp")
	

func _unhandled_input(event):
	if event.is_action_pressed("pause") and pause_title.text != tr("KEY_DEATH_MESSAGE"):
		self.paused = not paused
		scene_tree.set_input_as_handled()

func update_interface():
	health_potions.text = "%s" %PlayerData.health_potions
	battle_potions.text = "%s" %PlayerData.battle_potions
	ironskin_potions.text = "%s" %PlayerData.ironskin_potions

func set_paused(value: bool):
	paused = value
	scene_tree.paused = value
	pause_overlay.visible = value


func _on_AnimatedSprite_animation_finished():
	if _level_up_sprite.animation == "LVL2LevelUp":
		_level_up_sprite.play("Level2")
	elif _level_up_sprite.animation == "LVL3LevelUp":
		_level_up_sprite.play("Level3")
	elif _level_up_sprite.animation == "LVL4LevelUp":
		_level_up_sprite.play("Level4")
	elif _level_up_sprite.animation == "LVL5LevelUp":
		_level_up_sprite.play("Level5")


func _on_XpBar_player_level_up():
	play_level_up_animation()

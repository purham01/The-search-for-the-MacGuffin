extends "res://src/Actors/EnemyClass.gd"

var floaty_text_scene = preload("res://src/Effects/FloatingText.tscn") #ZA OVE PRELOAD NAREDBE PAZI GDI IH STAVLJAŠ JER MOGU STRGAT SVE VARIJABLE I NASLJEĐIVANJA U KLASI
var Undead_Sprites = preload("res://src/Actors/UndeadSprite.tscn")

signal start_fight
signal set_max_health(max_health)

export var experience := 20
export var move_direction = -1
export var ultimate = false
onready var playernode = get_tree().get_root().find_node("Player",true,false)
onready var teleport1 = get_tree().get_root().find_node("Teleport1",true,false)
onready var teleport2 = get_tree().get_root().find_node("Teleport2",true,false)
onready var SM = get_node("StateMachine")
onready var UI = get_tree().get_root().find_node("UserInterface",true,false)
onready var boss_music = get_tree().get_root().find_node("BossMusic",true,false)
onready var level_music = get_tree().get_root().find_node("LevelMusic",true,false)
onready var victory_music = get_tree().get_root().find_node("VictoryMusic",true,false)

onready var _animated_sprite = $AnimatedSprite
onready var _attack_area = $AttackArea
onready var _attack_hitbox = $AttackArea/Swing1
onready var _attack_detection_area = $AttackDetectionArea/CollisionShape2D
onready var player_detect_raycasts = $PlayerDetectionRaycasters
onready var cooldown_timer =$CooldownTimer

var reset_cooldown = false
var fight_started = false
var loot_pool = Items.loot
var target_position
var target_direction
var player_direction = null
var isHit = false
var isDead = false
var isAttacking = false
var canAttack = false

var teleporting = false
var teleported = false
var teleport_attacked = false
var teleport_to_target
var teleport_to
var teleport_threshold = 450
var _hurt_count = 0
var _hurt_count2= 0
var attack_counter = 0
var phase2_threshold
var chain_teleport = false
var teleport_counter = 0



func _ready():
	if float(Dialogic.get_variable("ultimate_boss")) == 1:
		ultimate = true
	if ultimate:
		teleport_threshold = 1525
		$EscapeArea/CollisionShape2D.shape.radius = 135
		max_health = 9000
		health = max_health
		_damage = 150
		minDamage = round(_damage*0.85)
		maxDamage = round(_damage*1.15)
		move_speed *=2
		var new_texture = StreamTexture.new()
		new_texture = load("res://assets/Enemies and Bosses/Undead executioner/WhitePallete.png")
		_animated_sprite.material.set_shader_param("palette",new_texture)
	phase2_threshold = max_health *0.5
	emit_signal("set_max_health",max_health)

func _on_VisibilityEnabler2D_screen_entered():
	if float(Dialogic.get_variable("boss_fight_started")) == 1:
		if !fight_started:
			SM.set_state(SM.states.idle)
			level_music.stop()
			boss_music.play()
			start_fight()

func start_fight():
	fight_started = true
	UI.boss_hp_bar.visible = true
	UI.start_boss_fight()
	emit_signal("start_fight")
	yield(UI.tween, "tween_completed")
	if SM.state == SM.states.cutscene:
		SM.set_state(SM.states.idle)

func _apply_gravity():
	_velocity.y += gravity * get_physics_process_delta_time()

func _apply_movement():
	_velocity.y = move_and_slide(_velocity, FLOOR_NORMAL).y

func _change_direction():
	if move_direction>0:
		_animated_sprite.flip_h = false
		_animated_sprite.offset.x = 0
#		_attack_area.position.x = 0
		_attack_area.scale.x = abs(_attack_area.scale.x)
		$AOEArea.scale.x = abs($AOEArea.scale.x)
		$AOEArea.position.x = 0
		$PlayerDetectionRaycasters/PlayerDetectionRaycaster.cast_to.x = abs($PlayerDetectionRaycasters/PlayerDetectionRaycaster.cast_to.x)
		$PlayerDetectionRaycasters/PlayerDetectionRaycasterBack.cast_to.x = -abs($PlayerDetectionRaycasters/PlayerDetectionRaycasterBack.cast_to.x)
		_attack_detection_area.position.x = abs(_attack_detection_area.position.x)
		$AttackDetectionArea.position.x = 0
	elif move_direction < 0:
		_animated_sprite.flip_h = true
		_animated_sprite.offset.x = -5
#		_attack_area.position.x = -5
		_attack_area.scale.x = -abs(_attack_area.scale.x)
		$AOEArea.scale.x = -abs($AOEArea.scale.x)
		$AOEArea.position.x = -5
		$PlayerDetectionRaycasters/PlayerDetectionRaycaster.cast_to.x = -abs($PlayerDetectionRaycasters/PlayerDetectionRaycaster.cast_to.x)
		$PlayerDetectionRaycasters/PlayerDetectionRaycasterBack.cast_to.x = abs($PlayerDetectionRaycasters/PlayerDetectionRaycasterBack.cast_to.x)
		_attack_detection_area.position.x = -abs(_attack_detection_area.position.x)
		$AttackDetectionArea.position.x = -5
		
func _friction():
		_velocity.x = lerp(_velocity.x,0,0.1)

func die():
	get_tree().call_group("undead_sprites", "die")
	isDead = true
	PlayerData.xp+= experience
	boss_music.stop()
	victory_music.play()
	set_collision_layer_bit(8, false)
	$HitBox/CollisionShape2D.set_deferred("disabled", true)
	$AttackDetectionArea/CollisionShape2D.set_deferred("disabled", true)
	for i in loot_pool:
		spawn_items(loot_pool.get(i),15)
	

func spawn_items(item_scene,amount):
	for Number in amount:
		if rng.randf() <= 0.8:
			var x_direction = rng.randf_range(-100, 100)
			var item = item_scene.instance()
			if item.name == "Potion":
				item.type = rng.randi() % 3
			get_tree().current_scene.call_deferred("add_child", item)
			item.position = global_position
			item.apply_impulse(Vector2(),Vector2(x_direction,-200))
			yield(get_tree().create_timer(0.2), "timeout")

func damage(amount, knockback_x, knockback_y):
	var damage_taken = amount - _defense * 0.5
	if damage_taken < 1:
		damage_taken=1
	_set_health(health - damage_taken)
#	$AnimationPlayer.play("damage")
	if health != 0:
		emit_signal("hurt")
	knockback_y = 0
	knockback(knockback_x, knockback_y)
	_createDamageTakenFloatingText(damage_taken)
	$AnimationPlayer.play("damage")
	_hurt_count += damage_taken
	print(_hurt_count)
	

func _createDamageTakenFloatingText(amount):
	var floaty_text = floaty_text_scene.instance()

#	floaty_text.position = $FloatingTextPosition.position
	floaty_text.position = Vector2(position.x+24,position.y-60)
	floaty_text.velocity = Vector2(rand_range(-50,50),-100)
	floaty_text.modulate = Color(rand_range(0.20, 1), rand_range(0.20, 1), rand_range(0.20, 1), 1.0)
	#orange color
#	floaty_text.modulate = Color(0.9, 0.5, 0.1, 1.0)

	floaty_text.set_text(amount)
	get_tree().get_root().call_deferred("add_child", floaty_text)

func detect_player():
	var target = null
	if !target_ref:
		for raycast in player_detect_raycasts.get_children():
			if raycast.is_colliding():
				target = raycast.get_collider()
				if target.name =="Player":
					set_target(target)
					target_position = target_ref.get_ref().global_position
	else:
		target_position = target_ref.get_ref().global_position
		target_direction = target_ref.get_ref().ability_direction
		teleport_to_target = target_position + Vector2(target_direction*20,-25)
		if (teleport_to_target.x < 0 or teleport_to_target.x > 1616) or (global_position.distance_to(teleport_to_target) < 100):
			teleport_to_target = target_position + Vector2(-target_direction*20,-25)
		

func chase():
	if target_ref:
		if !isAttacking:
			player_direction = (-global_position + target_position).normalized()
			_velocity.x = sign(player_direction.x) * move_speed
			move_direction = player_direction.x
		else:
			_velocity.x = 0


func _on_ResetCooldownArea_body_exited(body):
	if body.name =="Player":
		pass
		#reset_cooldown = true


func attack():
	if teleport_counter > 4:
		teleport_counter = 0
		teleport()
	elif _hurt_count > teleport_threshold:
		if ultimate and health <= phase2_threshold:
			_hurt_count = _hurt_count - teleport_threshold
			chain_teleport = true
			teleport_attack()
		else:
			_hurt_count = _hurt_count - teleport_threshold
			print(_hurt_count)
			teleport()
	elif attack_counter > 2:
		attack_counter = 0
		teleport_attack()
	elif canAttack and cooldown_timer.is_stopped():
		_animated_sprite.play("Attack")
	
	
	if reset_cooldown and !cooldown_timer.is_stopped():
		cooldown_timer.stop()
		reset_cooldown = false
	if chain_teleport:
		if _animated_sprite.animation == "Attack" and _animated_sprite.get_frame() == 5:
			teleport_counter+=1
			if teleport_counter > 4:
				chain_teleport = false
				isAttacking = false
				teleport_attacked = false
				teleporting = false
				SM.set_state(SM.states.idle)
			else:
				_animated_sprite.animation = "Skill1"
				_animated_sprite.frame = 2
				print(teleport_counter)
		elif _animated_sprite.animation == "Skill1" and _animated_sprite.get_frame() == 8 and !teleported:
			teleported = true
			global_position = teleport_to_target
			move_direction = (-global_position + target_ref.get_ref().position).normalized().x
		elif _animated_sprite.animation == "Skill1" and _animated_sprite.get_frame() == 9:
			teleported = false
			_animated_sprite.play("Attack")

	if _animated_sprite.animation == "Attack":
		isAttacking = true
	if _animated_sprite.animation == "Skill1" and _animated_sprite.get_frame() == 8:
		if !teleported:
			teleported = true
			if teleport_attacked:
				global_position = teleport_to_target
			else:
				global_position = teleport_to
			move_direction = (-global_position + target_ref.get_ref().position).normalized().x
	

func summon():
	SM.set_state(SM.states.summon)
	reset_cooldown = false
	var temp_defense = _defense
	_defense = 0
	var summon_count = 1
	yield(cooldown_timer,"timeout")
	while summon_count<5:
		_animated_sprite.play("Summon")
		var summoned_sprite = Undead_Sprites.instance()
		var sprite_position = "SpritePositions/Sprite"+String(summon_count)
		yield(_animated_sprite,"animation_finished")
		get_node(sprite_position).call_deferred("add_child",summoned_sprite)
		summon_count+=1
	SM.set_state(SM.states.idle)
	_defense = temp_defense
	cooldown_timer.start()

func teleport():
	_attack_detection_area.set_deferred("disabled", true)
	teleporting = true
	var player_to_teleport1 =  target_position - teleport1.global_position
	var player_to_teleport2 = target_position - teleport2.global_position
	if abs(player_to_teleport1.x) > abs(player_to_teleport2.x):
		teleport_to = teleport1.global_position
	else:
		teleport_to = teleport2.global_position

func teleport_attack():
	_attack_detection_area.set_deferred("disabled", true)
	teleporting = true
	teleport_attacked = true
#	var target_direction = target_ref.get_ref().ability_direction
#	teleport_to_target = target_position + Vector2(0,-28)

func _check_hitboxes():
	if isDead:
		$AttackArea/Swing1.set_deferred("disabled", true)
		$AttackArea/Swing2.set_deferred("disabled", true)
		$AOEArea/Skill1.set_deferred("disabled", true)
		
	if _animated_sprite.animation == "Attack" and _animated_sprite.get_frame() == 2:
		$AttackArea/Swing1.set_deferred("disabled", false)
	elif _animated_sprite.animation == "Attack" and _animated_sprite.get_frame() == 3:
		$AttackArea/Swing1.set_deferred("disabled", true)
	elif _animated_sprite.animation == "Attack" and _animated_sprite.get_frame() == 9:
		$AttackArea/Swing2.set_deferred("disabled", false)
	elif _animated_sprite.animation == "Attack" and _animated_sprite.get_frame() == 10:
		$AttackArea/Swing2.set_deferred("disabled", true)
	elif _animated_sprite.animation == "Skill1" and _animated_sprite.get_frame() == 6:
		$AOEArea/Skill1.set_deferred("disabled", false)
	elif _animated_sprite.animation == "Skill1" and _animated_sprite.get_frame() == 8:
		$AOEArea/Skill1.set_deferred("disabled", true)

func _on_AttackDetectionArea_body_entered(_body):
	canAttack = true

func _on_AttackDetectionArea_body_exited(_body):
	canAttack = false
	if !isDead:
		yield(_animated_sprite,"animation_finished")
	
func _on_AnimatedSprite_animation_finished():
	if _animated_sprite.animation =="Summon":
#		_animated_sprite.play("Idle")
		pass
	if _animated_sprite.animation =="Attack":
		isAttacking = false
		if fight_started:
			SM.set_state(SM.states.idle)
		else:
			SM.set_state(SM.states.cutscene)
		cooldown_timer.start()
		if ultimate and health <= max_health * 0.75:
			attack_counter +=1
	if _animated_sprite.animation =="Skill1":
		teleporting = false
		teleported = false
		_attack_detection_area.disabled = false
		if !teleport_attacked:
			cooldown_timer.start()
			summon()
		else:
			teleport_attacked = false

	if _animated_sprite.animation =="Death":
		set_target(null)
		get_tree().call_group("player", "summoningPet")
		UI.boss_hp_bar.visible = false
		queue_free()

func _on_AttackArea_area_entered(area):
	if area.is_in_group("Player_hitbox") or area.is_in_group("Hitboxes"):
		var target = area.get_parent()
		var knockback_direction = (target.global_position - global_position).normalized()
		var knockback_x = sign(knockback_direction.x) * knockback_strenght_x
# warning-ignore:unused_variable
		var knockback_y = sign(knockback_direction.y) * knockback_strenght_y
		var damage_dealt = rng.randi_range(minDamage, maxDamage)
		
		target.damage(damage_dealt, knockback_x, -knockback_strenght_y)


func _on_AOEArea_area_entered(area):
	if area.is_in_group("Player_hitbox"):
		var target = area.get_parent()
		var knockback_direction = (target.global_position - global_position).normalized()
		var knockback_x = sign(knockback_direction.x) * knockback_strenght_x
# warning-ignore:unused_variable
		var knockback_y = sign(knockback_direction.y) * knockback_strenght_y
		var damage_dealt = rng.randi_range(minDamage, maxDamage)
		
		target.damage(damage_dealt, knockback_x, -knockback_strenght_y)

func _on_EscapeArea_body_exited(body):
	if !teleported:
		if body.name == "Player":
			teleport_attack()








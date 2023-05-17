extends "res://src/Actors/Actor.gd"

var floaty_text_scene = preload("res://src/Effects/FloatingText.tscn")#ZA OVE PRELOAD NAREDBE PAZI GDI IH STAVLJAŠ JER MOGU STRGAT SVE VARIJABLE I NASLJEĐIVANJA U KLASI
var bloody_scene = preload("res://src/Effects/Blood_effects.tscn")
var parry_scene = preload("res://src/Effects/ParryEffect.tscn")
var pet = preload("res://src/Actors/SpritePet.tscn")

# warning-ignore:unused_signal
signal start_dialogue()
# warning-ignore:unused_signal
signal enter_combat()
signal exit_combat()

#inventory
enum Potion { HEALTH, BATTLE, IRONSKIN }
var battle_potion_buff = false
var ironskin_potion_buff = false


#movement
var stopping_friction = 0.8
var running_friction = 1
var isDodging = false
var canDodge = true

var isDashing = false
var canDash = true
var ability_direction = 1
export var dash_speed = 12 * Globals.UNIT_SIZE

var isAttacking = false
var AttackPoints = 3;
var isStunned = false
var isDead = false
var inCombat = false

var inDialogue = false

const WALL_JUMP_VELOCITY = Vector2(150,-200)

onready var pet_location = $PetTarget
onready var invincility_timer = $InvincibilityTimer
onready var cooldown_timer = $CooldownTimer
onready var wall_slide_cooldown = $WallSlideTimer
onready var wall_slide_sticky = $WallSlideStickyTimer
onready var coyote_timer = $CoyoteTimer
onready var jump_buffer = $JumpBuffer
onready var attack_timer = $AttackTimer
onready var attack_buffer = $AttackBuffer
onready var death_tween = $DeathTween

onready var _anim_player = $AnimationPlayer
onready var _animated_sprite = $AnimatedSprite
onready var body_collision = $CollisionShape2D
onready var player_hitbox = $HitBox/CollisionShape2D
onready var attack1_hitbox = $AttackArea/Attack1
onready var attack2_hitbox = $AttackArea/Attack2
onready var dashattack_hitbox = $AttackArea/DashAttack
onready var left_wall_raycasts = $WallRaycasts/LeftWallRaycast
onready var right_wall_raycasts = $WallRaycasts/RightWallRaycast
onready var magnet_area = $MagnetArea
onready var attack_area = $AttackArea

onready var npc_raycasts = $NPCRaycasts
onready var xp_bar = get_tree().get_root().find_node("XpBar",true,false)
onready var SM = get_node("StateMachine")

#SFX
onready var running_sfx = $AudioLibrary/RunSFX

#EFFECTS
onready var battle_potion_particles = $BattlePotionParticles
onready var ironskin_potion_particles = $IronskinPotionParticles

var wall_direction = 1
var move_direction = 1
var wall_jump_direction = 0

var being_targeted_by = []

func _ready():
	PlayerData.load_data()
	if PlayerData.hasPet:
		var summoned_pet = pet.instance()
		get_tree().current_scene.call_deferred("add_child", summoned_pet)
		summoned_pet.position = $PetTarget.global_position
# warning-ignore:return_value_discarded
	PlayerData.connect("health_updated",self,"on_health_updated")
	xp_bar.connect("player_level_up",self, "_on_XpBar_player_level_up")

func start_cutscene():
	_velocity = Vector2.ZERO
	inDialogue = true
	SM.set_state(SM.states.in_dialogue)

func end_cutscene():
	inDialogue = false
	SM.set_state(SM.states.idle)

func _process(_delta):
	if _animated_sprite.animation == "Dash attack" and _animated_sprite.get_frame() == 7:
		if !attack_buffer.is_stopped(): 
			attack_buffer.stop()
			attack()
	
	if _animated_sprite.animation == "Crouch" and _animated_sprite.get_frame() == 1:
		isDodging = true
	elif _animated_sprite.animation == "Crouch" and _animated_sprite.get_frame() == 5:
		isDodging = false

func _createFloatingText(amount, color = Color(rand_range(0.20, 1), rand_range(0.20, 1), rand_range(0.20, 1), 1.0)):
	var floaty_text = floaty_text_scene.instance()
	
	floaty_text.position = Vector2(position.x+10,position.y-35)
	floaty_text.velocity = Vector2(rand_range(-50,50),-100)
	#rainbow colors
	floaty_text.modulate = color

	floaty_text.set_text(amount)
	get_parent().call_deferred("add_child", floaty_text)


func _create_blood():
	var bloody_effect = bloody_scene.instance()
	get_node("Blood").call_deferred("add_child",bloody_effect)

func on_targeted(enemy):
	if !$ExitCombatTimer.is_stopped():
		$ExitCombatTimer.stop()
	get_tree().call_group("DialogueNode", "close_dialog_event", 0.2)
	being_targeted_by.insert(being_targeted_by.size(),enemy)
	if !inCombat:
		inCombat= true
	print(being_targeted_by)
	_createFloatingText("Targeted by " + String(enemy.name),Color(0.890196, 0.078431, 0.078431))

func on_untargeted(enemy):
	being_targeted_by.erase(enemy)
	print(being_targeted_by)
	_createFloatingText("Untargeted by " + String(enemy.name),Color(0.890196, 0.078431, 0.078431))
	if being_targeted_by.empty():
		$ExitCombatTimer.start()
		

func add_potion(type):
	$AudioLibrary/PickUpItem.play()
	if type == Potion.HEALTH:
		PlayerData.health_potions += 1
		_createFloatingText(tr("KEY_HP_POT_POPUP"), Color(1,0.01,0.01,1))
	elif type == Potion.BATTLE:
		PlayerData.battle_potions += 1
		_createFloatingText(tr("KEY_BATTLE_POT_POPUP"), Color(0.5,0.01,0.85,1))
	else:
		PlayerData.ironskin_potions += 1
		_createFloatingText(tr("KEY_IRONSKIN_POT_POPUP"),Color(1, 0.937255, 0,1))

func ironskin_buff():
	if PlayerData.ironskin_potions > 0 and !ironskin_potion_buff:
				ironskin_potion_buff = true
				print("Ironskin - 1")
				PlayerData.ironskin_potions = PlayerData.ironskin_potions - 1
				ironskin_potion_particles.emitting = true
				var temp_defense= PlayerData.defense
				PlayerData.defense += 10
				yield (get_tree().create_timer(20),"timeout")
				ironskin_potion_particles.emitting = false
				ironskin_potion_buff = false
				PlayerData.defense = temp_defense

func battle_buff():
	if PlayerData.battle_potions > 0 and !battle_potion_buff:
		print("Battle - 1")
		battle_potion_buff = true
		PlayerData.battle_potions = PlayerData.battle_potions - 1
		battle_potion_particles.emitting =true
		var temp_damage= PlayerData.damage
		print(PlayerData.damage)
		PlayerData.damage *= 1.2
		print(PlayerData.damage)
		yield (get_tree().create_timer(20),"timeout")
		battle_potion_particles.emitting = false
		PlayerData.damage = temp_damage
		battle_potion_buff = false
		print(PlayerData.damage)

func _on_XpBar_player_level_up():
	PlayerData.max_health += 50
	PlayerData.damage += 5
	PlayerData.defense += 5
	$AnimationPlayer.play("LevelUpLabel")
	PlayerData.set_health(PlayerData.max_health)
	$AudioLibrary/LevelUp.play()

func _apply_gravity():
	_velocity.y += gravity * get_physics_process_delta_time()

func _apply_movement():
	var was_on_floor= is_on_floor()
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL)
	if !is_on_floor() and was_on_floor:
		coyote_timer.start()
	if is_on_floor() and !jump_buffer.is_stopped() and !isDashing:
		jump_buffer.stop()
		jump()

func jump():
	_velocity.y = max_jump_velocity

func wall_jump():
	var wall_jump_velocity = WALL_JUMP_VELOCITY
	wall_jump_velocity.x *= -wall_direction
	_velocity = wall_jump_velocity
	wall_jump_direction = wall_direction

func move_in_cutscene():
	start_cutscene()
	move_direction = ability_direction
#	if abs(_velocity.x)<=800:
#		_velocity.x = lerp(_velocity.x, move_speed * move_direction, _get_h_weight())
	_velocity.x = 100 * move_direction

func _handle_move_input_V2():
	if abs(_velocity.x)<=800:
		_velocity.x = lerp(_velocity.x, move_speed * move_direction, _get_h_weight())
	change_direction()

func _apply_dash():
	_velocity.x = lerp(_velocity.x, dash_speed * ability_direction, _get_h_weight())

func _get_h_weight():
	if is_on_floor():
		return 0.2
	else:
		if move_direction == 0: 
			return 0.02
		elif move_direction == sign(_velocity.x) and abs(_velocity.x) > move_speed:
			return 0.0
		else:
			return 0.1

func _update_move_direction():
	move_direction = int(Input.is_action_pressed("move_right")) -int(Input.is_action_pressed("move_left"))
	if wall_jump_direction != 0 and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")):
		wall_jump_direction = 0

func change_direction():
	if move_direction>0 or wall_jump_direction <0: #moving right
		_animated_sprite.flip_h = false
		_animated_sprite.offset.x = 0
		attack_area.position.x = 0
		attack1_hitbox.position.x = abs(attack1_hitbox.position.x)
		attack1_hitbox.scale.x = abs(attack1_hitbox.scale.x)
		attack2_hitbox.position.x = abs(attack2_hitbox.position.x)
		attack2_hitbox.scale.x = abs(attack2_hitbox.scale.x)
		dashattack_hitbox.scale.x = abs(dashattack_hitbox.scale.x)
		ability_direction = 1
		battle_potion_particles.process_material.direction.x = -1
		ironskin_potion_particles.process_material.direction.x = -1
		$Parry.position.x = abs($Parry.position.x)
		$PetTarget.position.x = -abs($PetTarget.position.x)
	elif move_direction<0 or wall_jump_direction >0: #moving left
		_animated_sprite.flip_h = true
		_animated_sprite.offset.x = -10
		attack_area.position.x = -10
		attack1_hitbox.position.x = -abs(attack1_hitbox.position.x)
		attack1_hitbox.scale.x = -abs(attack1_hitbox.scale.x)
		attack2_hitbox.position.x = -abs(attack2_hitbox.position.x)
		attack2_hitbox.scale.x = -abs(attack2_hitbox.scale.x)
		dashattack_hitbox.scale.x = -abs(dashattack_hitbox.scale.x) 
		ability_direction = -1
		battle_potion_particles.process_material.direction.x = 1
		ironskin_potion_particles.process_material.direction.x = -1
		$Parry.position.x = -abs($Parry.position.x)
		$PetTarget.position.x = abs($PetTarget.position.x)
	else:
		battle_potion_particles.process_material.direction.x = 0
		ironskin_potion_particles.process_material.direction.x = 0
		

func _handle_wall_slide_sticky():
	if move_direction != 0 and move_direction != wall_direction:
		if wall_slide_sticky.is_stopped():
			wall_slide_sticky.start()
	else:
		wall_slide_sticky.stop()

func _update_wall_direction():
	var is_near_wall_left = _check_is_valid_wall(left_wall_raycasts)
	var is_near_wall_right = _check_is_valid_wall(right_wall_raycasts)
	if is_near_wall_left and is_near_wall_right:
		wall_direction = move_direction
	else:
		wall_direction = - int(is_near_wall_left) + int(is_near_wall_right) 

func _check_is_valid_wall(wall_raycasts):
	for raycast in wall_raycasts.get_children():
		if raycast.is_colliding():
			var dot = acos(Vector2.UP.dot(raycast.get_collision_normal()))
			if dot > PI * 0.35 && dot < PI * 0.55:
				return true
	return false

func _cap_gravity_wall_slide():
	var max_velocity = 4*Globals.UNIT_SIZE if !Input.is_action_pressed("crouch") else 8*Globals.UNIT_SIZE
	_velocity.y = min(abs(_velocity.y), max_velocity)

func friction():
	# služi za usporavanje slika kada je u jednom od ovih stanja, inače se stalno kreče naprijed
	#nisam siguran da li da usporavamo tijekom stunna ili ne, ali je za sada tu (više ne)
	#ovo se također može koristiti ako na nekim plohama želimo lika ubrzati ili usporiti, na to utječe running_friction
	if isAttacking or isDead:
		_velocity.x *= stopping_friction
	elif isDashing and _animated_sprite.get_frame() > 4: #modificiranje usporavanje tijekom kraja dasha
		_velocity.x *= 0.8
	else:
		_velocity.x *= running_friction

func calculate_stomp_velocity(linear_velocity: Vector2, impulse:float):
	var out:= linear_velocity
	out.y = -impulse
	return out

func die():
	#ovdje se poziva PlayerData koji ima signal koji stavlja meni s textom you died kada umremo, ovo se poziva nakon death animacije
	PlayerData .deaths += 1
	$AudioLibrary/DeathMusic.play()

#func save():
#	var save_dict = {
#		"filename" : get_filename(),
#		"parent" : get_parent().get_path(),
#		"pos_x" : position.x, # Vector2 is not supported by JSON
#		"pos_y" : position.y,
#		"health": health,
#		"max_health": max_health,
#		"level": level,
#		"xp": xp,
#		"xp_to_next_level": xp_next_level
#	}
#	return save_dict

func attack():
	if AttackPoints == 3:
		_animated_sprite.play("Attack1")
		attack_timer.start()
		AttackPoints = 2  
	elif AttackPoints ==  2:
		attack1_hitbox.disabled = true
		_animated_sprite.play("Attack2")
		attack_timer.start()
		AttackPoints = 1
	elif AttackPoints ==  1:
		attack2_hitbox.disabled = true
		_animated_sprite.play("Attack3")
		attack_timer.start()
		AttackPoints = 0


func check_hitboxes():
	#provjere hitboxa po napadima i po frameu animacije napada, hitbox se pali i gasi na odredeni frame
	if isStunned: #ako je napad prekinut jer je igrač udaren onda se svi hitboxi gase
		attack1_hitbox.disabled = true
		attack2_hitbox.disabled= true
		dashattack_hitbox.disabled = true
	else:
		#attack1
		if _animated_sprite.animation == "Attack1" and _animated_sprite.get_frame() == 5:
			attack1_hitbox.disabled = false
		elif _animated_sprite.animation == "Attack1" and _animated_sprite.get_frame() == 8:
			attack1_hitbox.disabled = true
		#attack2
		if _animated_sprite.animation == "Attack2" and _animated_sprite.get_frame() == 0:
			attack2_hitbox.disabled = false
		elif _animated_sprite.animation == "Attack2" and _animated_sprite.get_frame() == 3:
			attack2_hitbox.disabled = true
		#attack3
		if _animated_sprite.animation == "Attack3" and _animated_sprite.get_frame() == 3:
			attack1_hitbox.disabled = false
		elif _animated_sprite.animation == "Attack3" and _animated_sprite.get_frame() == 6:
			attack1_hitbox.disabled = true
		#dashattack
		if _animated_sprite.animation == "Dash attack" and _animated_sprite.get_frame() == 3:
			dashattack_hitbox.disabled = false
		elif _animated_sprite.animation == "Dash attack" and _animated_sprite.get_frame() == 5:
			dashattack_hitbox.disabled = true
	
func _on_AnimatedSprite_animation_finished():
	if _animated_sprite.animation == "Attack1" or _animated_sprite.animation == "Attack2" or _animated_sprite.animation == "Attack3":
		if !attack_buffer.is_stopped(): #ovdje se provjerava je li uključen attack buffer koji se upali kada se stisni "attack" tijekom drugog napada
			attack_buffer.stop()		#ako je bio aktiviran se na kraju animacije zaustavlja i pokreće se idući napad
			attack()					#na ovaj način se ne prekidaju animacije napada
		else:
			isAttacking = false
			attack1_hitbox.disabled = true #Ovo su samo dodatne provjere ako se nije ugasio hitbox iz bilo kojeg razloga
			attack2_hitbox.disabled= true
		
	if _animated_sprite.animation == "Dash attack":
		dashattack_hitbox.disabled = true #Ovo su samo dodatne provjere ako se nije ugasio hitbox iz bilo kojeg razloga
		isAttacking = false
		AttackPoints = 0

	elif _animated_sprite.animation == "Dash":
		isDashing = false

	if _animated_sprite.animation == "Death":
		death_tween.interpolate_callback(self, 0.5, "die")
		death_tween.start()
	
	if _animated_sprite.animation == "Hurt":
		isStunned = false

	if _animated_sprite.animation == "Slide" or _animated_sprite.animation == "Crouch":
		isDodging = false

#timers
func _on_AttackTimer_timeout():
	AttackPoints = 3;
	isAttacking = false

func _on_DashTimer_timeout():
	canDash = true
	canDodge = true

func damage(amount, knockback_x, knockback_y):
	if invincility_timer.is_stopped() and !isDodging and !isDead:
		invincility_timer.start()
		var damage_taken = amount - PlayerData.defense* 0.5
		if damage_taken < 1:
			damage_taken=1
		PlayerData.set_health(PlayerData.health-damage_taken)
		_createFloatingText(damage_taken)
		_create_blood()
		if PlayerData.health != 0:
			emit_signal("hurt")
		knockback(knockback_x,knockback_y)

func on_health_updated(_heal):
	if PlayerData.health != PlayerData.max_health:
		magnet_area.set_collision_mask_bit(6, true)
	else:
		magnet_area.set_collision_mask_bit(6, false)
	if PlayerData.health == 0:
		$AudioLibrary/GameOverSound.play()
		emit_signal("killed")

#opcija 2 za hitbox
func _on_AttackArea_area_entered(area):
	if area.is_in_group("AttackAreas"):
		invincility_timer.start()
		emit_signal("on_hit_enemy")
		var parry_effect = parry_scene.instance()
		parry_effect.position = $Parry.position
		call_deferred("add_child",parry_effect)

	if area.is_in_group("Hitboxes"):
		var target = area.get_parent()
		var knockback_direction = (target.global_position - global_position).normalized()
		var knockback_x = sign(knockback_direction.x) * knockback_strenght_x
		var knockback_y
		if knockback_direction.y < -0.1 or knockback_direction.y > 0.1:
			knockback_y = sign(knockback_direction.y) * knockback_strenght_y
		else:
			knockback_y = 0
		var damage_dealt = rng.randi_range(PlayerData.minDamage, PlayerData.maxDamage)
		#damage multiplier ovisno o napadu
		if _animated_sprite.animation == "Attack2":
			damage_dealt = round(damage_dealt * 1.1)
		elif _animated_sprite.animation == "Attack3":
			damage_dealt = round(damage_dealt * 1.2)
		elif _animated_sprite.animation == "Dash attack":
			damage_dealt = round(damage_dealt * 1.3)
			knockback_x = 0
			knockback_y = 2 * -knockback_strenght_y
		if PlayerData.hasPet:
			if rng.randf() <= 0.01:
				damage_dealt *=2
				print("Critical hit!")
		target.damage(damage_dealt, knockback_x, knockback_y)


func _on_ExitCombatTimer_timeout():
	inCombat = false
	print("No longet in combat")
	emit_signal("exit_combat")

func summoningPet():
	if PlayerData.hasPet == false:
		PlayerData.hasPet = true
		var summoned_pet = pet.instance()
		get_tree().current_scene.call_deferred("add_child", summoned_pet)
		summoned_pet.position = $PetTarget.global_position

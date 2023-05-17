extends "res://src/StateMachine/StateMachine.gd"



func _ready():
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("fall")
	add_state("attacking")
	add_state("dashing")
	add_state("dash_attacking")
	add_state("wall_sliding")
	add_state("dead")
	add_state("crouch")
	add_state("slide")
	add_state("stun")
	add_state("in_dialogue")
	call_deferred("set_state", states.idle)

func _input(event):
	#jumping criteria
	if [states.idle, states.run].has(state) or !parent.coyote_timer.is_stopped():
		if event.is_action_pressed("jump"):
			parent.coyote_timer.stop()
			parent.jump()
		
	if [states.fall, states.dashing].has(state):
		if event.is_action_pressed("jump"):
			parent.jump_buffer.start()
	
	if [states.jump].has(state):
		if event.is_action_released("jump") and (parent._velocity.y < parent.min_jump_velocity):
			parent._velocity.y = parent.min_jump_velocity
	
	if [states.wall_sliding].has(state):
		if event.is_action_pressed("jump"):
			parent.wall_jump()
			set_state(states.jump)
	
	
	if [states.idle, states.run, states.attacking, states.dash_attacking].has(state) and parent.AttackPoints != 0:
		if Input.is_action_just_pressed("attack"):
			if !parent.isAttacking:
				parent.isAttacking = true
				parent.attack()
				set_state(states.attacking)
			else:
				parent.attack_buffer.start()
			

	#code for dodging
	if parent.canDodge:
		if Input.is_action_just_pressed("crouch"):
			if [states.idle].has(state):
				set_state(states.crouch)
			elif [states.run].has(state):
				set_state(states.slide)
	
	#code for dashing
	if [states.idle, states.run].has(state) and parent.canDash:
		if Input.is_action_just_pressed("dash"):
			set_state(states.dashing)
	if [states.dashing].has(state):
		if Input.is_action_just_pressed("attack"):
			set_state(states.dash_attacking)
	
	#code for dialogue
	if ![states.in_dialogue].has(state) and !parent.inCombat:
		if Input.is_action_just_pressed("Interact"):
			for raycast in parent.npc_raycasts.get_children():
				if raycast.is_colliding():
					parent.emit_signal("start_dialogue", raycast.get_collider())
					break
	
	#drinking potions
	if event.is_action_pressed("drink_health"):
		if PlayerData.health_potions > 0 and PlayerData.health != PlayerData.max_health:
			PlayerData.health_potions = PlayerData.health_potions - 1
			PlayerData.health = min(PlayerData.health + 0.5*PlayerData.max_health, PlayerData.max_health)
			
	if event.is_action_pressed("drink_battle"):
		parent.battle_buff()
	if event.is_action_pressed("drink_ironskin"):
		parent.ironskin_buff()


func _state_logic(_delta):
	parent._apply_gravity()
	parent._apply_movement()
	parent.check_hitboxes()
	if ![states.jump, states.fall, states.wall_sliding].has(state):
		parent.friction()
	if ![states.dead, states.stun, states.in_dialogue].has(state):
		parent._update_move_direction()
		parent._update_wall_direction()
		if ![states.attacking, states.dash_attacking, states.wall_sliding, states.crouch].has(state):
			if [states.dashing, states.slide].has(state):
				parent._apply_dash()
			else:
				parent._handle_move_input_V2()
		if [states.wall_sliding].has(state):
			parent._cap_gravity_wall_slide()
			parent._handle_wall_slide_sticky()
	if [states.run].has(state):
		if parent._animated_sprite.get_frame() == 2 or parent._animated_sprite.get_frame() == 6:
			if !parent.running_sfx.is_playing():
				parent.running_sfx.play()
		
func _get_transition(_delta):
	match state:
		states.idle:
			if parent.isDashing:
				return states.dashing
			if !parent.is_on_floor():
				if parent._velocity.y < 0:
					return states.jump
				elif parent._velocity.y > 0:
					return states.fall
			elif parent.move_direction != 0:
				return states.run
			
		states.run:
			if parent.isDashing:
				return states.dashing
			if !parent.is_on_floor():
				if parent._velocity.y < 0:
					parent.running_sfx.play()
					return states.jump
				elif parent._velocity.y > 0:
					return states.fall
			elif parent.move_direction == 0:
				return states.idle
				
		states.jump:
			if parent.wall_direction != 0 and parent.ability_direction == parent.wall_direction and parent.wall_slide_cooldown.is_stopped() and parent.is_on_wall():
				return states.wall_sliding
			elif parent.is_on_floor():
				return states.idle
			elif parent._velocity.y >= 0:
				parent._animated_sprite.play("UpToFall")
				
		states.fall:
			if parent.wall_direction != 0 and parent.ability_direction == parent.wall_direction and parent.wall_slide_cooldown.is_stopped() and parent.is_on_wall():
				return states.wall_sliding
			elif parent.is_on_floor():
				parent.running_sfx.play()
				return states.idle
			elif parent._velocity.y < 0:
				return states.jump

		states.attacking:
			if !parent.isAttacking:
				return states.idle
		
		states.dashing:
			if !parent.isDashing:
				return states.idle
				
		states.dash_attacking:
			if !parent.isAttacking:
				return states.idle

		states.wall_sliding:
			if parent.is_on_floor():
				return states.idle
			elif parent.wall_direction == 0:
				return states.fall

		states.slide:
			if !parent.isDodging:
				return states.idle
			
		states.stun:
			if !parent.isStunned:
				return states.idle
	return null

func _enter_state(new_state, old_state):
	match new_state:
		states.idle:
			parent._animated_sprite.play("idle")
		states.run:
			parent._animated_sprite.play("run")
		states.jump:
			parent._animated_sprite.play("jump")
		states.fall:
			parent._animated_sprite.play("Fall")
		states.dashing:
			parent.isDashing = true
			parent._animated_sprite.play("Dash")
		states.dash_attacking:
			parent.AttackPoints = 2
			parent.isDashing = false
			parent.isAttacking = true
			parent.attack_timer.start()
			parent._animated_sprite.play("Dash attack")
		states.wall_sliding:
			if parent.wall_direction>0:
					parent._animated_sprite.offset= Vector2(3,3)
			else:
				parent._animated_sprite.offset= Vector2(-15,3)
			parent._animated_sprite.play("WallSlide")
		states.dead:
			parent._animated_sprite.play("Death")
		states.crouch:
			parent.canDodge = false
			parent._velocity=Vector2.ZERO
			parent.cooldown_timer.start()
			parent._animated_sprite.play("Crouch")
		states.slide:
			parent.canDodge = false
			parent.isDodging = true
			parent.cooldown_timer.start()
			parent.set_collision_mask_bit(1, false)
			parent.set_collision_mask_bit(8, false)
			parent._animated_sprite.play("Slide")
		states.stun:
			parent._animated_sprite.play("Hurt")
		states.in_dialogue:
			if parent._anim_player.current_animation != "Exit_level":
				parent._animated_sprite.play("idle")
			parent.isDashing = false
			parent.isAttacking = false
			parent.isDodging = false

func _exit_state(old_state, new_state):
	match old_state:
		states.wall_sliding:
			if parent.wall_direction < 0:
				parent._animated_sprite.offset= Vector2(-10,0)
			else: 
				parent._animated_sprite.offset= Vector2(0,0)
			parent.wall_slide_cooldown.start()
		states.slide:
			parent.set_collision_mask_bit(1, true)
			parent.set_collision_mask_bit(8, true)

func _on_Player_killed():
	parent.isDead = true
	set_state(states.dead)

func _on_Player_hurt():
	parent.AttackPoints = 3
	parent._velocity.x = 0
	parent.isAttacking = false
	parent.isDashing = false
	parent.isStunned = true
	set_state(states.stun)

func _on_WallSlideStickyTimer_timeout():
	if state == states.wall_sliding:
		set_state(states.fall)


func _on_AnimatedSprite_animation_finished():
	if parent._animated_sprite.animation == "UpToFall":
		set_state(states.fall)
	if parent._animated_sprite.animation == "Crouch":
		set_state(states.idle)

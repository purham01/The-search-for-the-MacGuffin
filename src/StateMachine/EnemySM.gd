extends "res://src/StateMachine/StateMachine.gd"


func _ready():
	add_state("idle")
	add_state("combat_idle")
	add_state("attack")
	add_state("jump")
	add_state("hurt")
	add_state("dead")
	add_state("run")
	add_state("alert")
	add_state("return")
	call_deferred("set_state", states.idle)
	
func _state_logic(_delta):
	parent.SightCheck()
	parent._check_hitboxes()
	parent._apply_gravity()
	parent._apply_movement()
	parent._friction()
	if ![states.dead, states.hurt, states.attack].has(state):
		if ![states.jump].has(state):
			parent._detect_jump()
			parent.attack()
		parent._detect_player()
		parent._handle_movement()
		parent._change_direction()

func _get_transition(_delta):
	match state:
		states.idle:
			if parent._velocity.x != 0:
				return states.run
			if parent._velocity.y < 0:
				return states.jump
			if parent.isAlert:
				return states.combat_idle
				
		states.run:
			if parent._velocity.x == 0 and !parent.isAlert:
				return states.idle
			if parent._velocity.x == 0 and parent.isAlert:
				return states.combat_idle
			if parent._velocity.y < 0:
				return states.jump
			

		states.jump:
			if parent.is_on_floor():
				return states.idle

		states.attack:
			if !parent.isAttacking and !parent.isAlert:
				return states.idle
			if !parent.isAttacking:
				return states.combat_idle

		states.combat_idle:
			if parent._velocity.x != 0:
				return states.run
			if parent._velocity.y < 0:
				return states.jump
			if !parent.isAlert:
				return states.idle
			if parent.isAttacking:
				return states.attack
		
		states.hurt:
			if !parent.isHit:
				return states.combat_idle

func _enter_state(_new_state, _old_state):
	match _new_state:
		states.idle:
			parent._animated_sprite.play("default")
		states.run:
			parent._animated_sprite.play("Run")
		states.jump:
			parent._animated_sprite.play("Jump")
		states.hurt:
			parent.isHit = true
			parent._animated_sprite.play("Hurt")
		states.combat_idle:
			parent._animated_sprite.play("CombatIdle")
		states.dead:
			parent._animated_sprite.play("die")
			parent.die()

func _exit_state(_old_state, _new_state):
	pass

func _on_HeavyBandit_killed():
	parent._velocity = Vector2.ZERO
	set_state(states.dead)

func _on_HeavyBandit_hurt():
	if !parent.isAlert:
		parent.set_alert()
	parent._velocity.x = 0
	parent.isHit = true
	if ![states.attack].has(state):
		parent.isAttacking = false
		set_state(states.hurt)
	else:
		parent._animation_player.play("damage_flash")

extends "res://src/StateMachine/StateMachine.gd"

func _ready():
	add_state("chase")
	add_state("attack")
	add_state("summon")
	add_state("teleport")
	add_state("idle")
	add_state("dead")
	add_state("cutscene")
	call_deferred("set_state", states.cutscene)

func _state_logic(_delta):
	parent._check_hitboxes()
	parent._apply_gravity()
	parent._apply_movement()
	if ![states.cutscene].has(state):
		parent.detect_player()
	if ![states.chase].has(state):
		parent._friction()
	if ![states.dead].has(state):
		if ![states.attack].has(state):
			parent._change_direction()
		if [states.chase].has(state):
			parent.chase()
		if ![states.summon].has(state):
			parent.attack()

func _get_transition(_delta):
	match state:
		states.idle:
			if parent.cooldown_timer.is_stopped():
				return states.chase

		states.chase:
			if !parent.cooldown_timer.is_stopped():
				return states.idle
			elif parent.isAttacking:
				return states.attack
			elif parent.teleporting:
				return states.teleport
				
		states.attack:
			if parent.teleporting and !parent.isAttacking:
				return states.teleport
			elif !parent.isAttacking:
				return states.chase
		
		states.teleport:
			if !parent.teleporting:
				return states.chase
	return null

func _enter_state(_new_state, _old_state):
	match _new_state:
		states.cutscene:
			parent._animated_sprite.play("Idle")
		states.idle:
			parent._animated_sprite.play("Idle")
			parent._velocity = Vector2.ZERO
		states.chase:
			parent._animated_sprite.play("Float")
		states.teleport:
			parent._animated_sprite.play("Skill1")
		states.summon:
			parent._animated_sprite.play("Idle")
		states.dead:
			parent.die()
			parent._animated_sprite.play("Death")


func _exit_state(_old_state, _new_state):
	pass


func _on_Undead_Executioner_killed():
	parent.isAttacking = false
	parent._animated_sprite.stop()
	set_state(states.dead)

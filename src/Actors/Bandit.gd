extends "res://src/Actors/EnemyClass.gd"
var floaty_text_scene = preload("res://src/Effects/FloatingText.tscn") #ZA OVE PRELOAD NAREDBE PAZI GDI IH STAVLJAŠ JER MOGU STRGAT SVE VARIJABLE I NASLJEĐIVANJA U KLASI
var bloody_scene = preload("res://src/Effects/Blood_effects.tscn")

export var alert_distance = 12.5 * Globals.UNIT_SIZE

export var experience := 20
export var move_direction = -1

onready var _animated_sprite = $AnimatedSprite
onready var _animation_player = $AnimationPlayer2
onready var _health_bar = $HealthBar
onready var _attack_area = $AttackArea
onready var _attack_hitbox = $AttackArea/CollisionPolygon2D
onready var _anim_player=$AnimationPlayer
onready var _attack_detection_area = $AttackDetectionArea/CollisionShape2D
onready var death_tween = $DeathTween
onready var pop_up_sprite = $PopUpSprite
onready var detection_timer = $DetectionTimer
onready var player_detect_raycasts = $PlayerDetectionRaycasters
onready var jump_detection_raycasts = $JumpDetectionRaycasters

onready var map_navigation = get_tree().get_root().find_node("MapNavigation",true,false)
onready var debug_path= get_tree().get_root().find_node("DEBUG_path_line",true,false)
onready var debug_next_step = get_tree().get_root().find_node("DEBUG_next_step",true,false)
onready var SM = get_node("StateMachine")

var player_seen
var tracking_player 
var starting_position
var starting_direction
var _current_path = []
var destination
var target_direction = null
var move_in_direction = null
var target_position = null
var isAlert = false
var isHit = false
var isDead = false
var isAttacking = false
var canAttack = false

func _ready():
	set_physics_process(false)
	starting_position = global_position
	starting_direction = move_direction

func _apply_gravity():
	_velocity.y += gravity * get_physics_process_delta_time()

func _apply_movement():
	_velocity.y = move_and_slide(_velocity, FLOOR_NORMAL).y

func _handle_movement():
	if !_current_path.empty():
		target_direction = (target_position - position).normalized() 
		var direction_to_start= (starting_position - position).normalized()
#		if destination and isAlert:
#			move_in_direction = (-global_position + destination).normalized()
#		else:
#			move_in_direction = (-global_position + starting_position).normalized()
		var next_move = _current_path[0]
		var y_distance = abs(position.y -  next_move.y)
		
		debug_next_step.rect_position = next_move
		
		move_in_direction = (-global_position + next_move).normalized()
		
		if abs(move_in_direction.x) < 0.5 and y_distance < 10:
			_current_path.remove(0)
			_update_debug_line()

		if is_on_floor() and abs(target_direction.x) < 0.5:
			if target_direction == direction_to_start:
				move_direction = starting_direction
			_current_path = []
			return

		if !isAttacking:
			_velocity.x = sign(move_in_direction.x) * move_speed
			move_direction = move_in_direction.x
		else:
			_velocity.x = 0
	else:
		_velocity.x = 0

func Search():
	var path_to_destination  = map_navigation.get_simple_path(get_global_position(), destination,true)
	
	var starting_point = get_global_position()
	var move_distance = move_speed* get_physics_process_delta_time()
	if !_is_path_reachable(path_to_destination):
		path_to_destination = _calculate_alternate_path()
	_current_path = path_to_destination

	if _current_path.size() > 0:
			_current_path.remove(0)

	_update_debug_line()
#	for point in range(_current_path.size()):
#		var next_step = _current_path[0]
#		debug_next_step.rect_position = next_step
#		var distance_to_next_point = starting_point.distance_to(next_step)
#		if move_distance <= distance_to_next_point:
#			break
#		move_distance -= distance_to_next_point
#		starting_point = next_step
#		_current_path.remove(0)

		
func Return():
	var path_to_starting_position  = map_navigation.get_simple_path(get_global_position(), starting_position, true)
	target_position = starting_position
	var starting_point = get_global_position()
	if starting_point.x == starting_position.x:
		return
	var move_distance = move_speed* get_physics_process_delta_time()
	if !_is_path_reachable(path_to_starting_position):
		path_to_starting_position = _calculate_alternate_path()
	_current_path = path_to_starting_position

	if _current_path.size() > 0:
			_current_path.remove(0)

	_update_debug_line()

#	for point in range(_current_path.size()):
#		var next_step = _current_path[0]
#		debug_next_step.rect_position = next_step
#		var distance_to_next_point = starting_point.distance_to(next_step)
#		if move_distance <= distance_to_next_point:
#			break
#		move_distance -= distance_to_next_point
#		starting_point = next_step
#		_current_path.remove(0)

func _update_debug_line():
	debug_path.clear_points()
	debug_path.add_point(global_position)
	for p in _current_path:
		debug_path.add_point(p)


# Check if all ascending sections have Y distance reachable by the character's jump
func _is_path_reachable(path):
	var previous = position
	for current in path:
		if previous.y > current.y and abs(previous.y - current.y) > min_jump_height*4:
			return false
		previous = current
	return true

func _calculate_alternate_path():
	var offset = Vector2(40, 0)
	var alt_1 = map_navigation.get_simple_path(position - offset, target_position, true)
	var alt_2 = map_navigation.get_simple_path(position + offset, target_position, true)

	var is_alt_1_reachable = _is_path_reachable(alt_1)
	var is_alt_2_reachable = _is_path_reachable(alt_2)

	if not (is_alt_1_reachable or is_alt_2_reachable):
		return []

	if is_alt_1_reachable and not is_alt_2_reachable:
		return alt_1

	if not is_alt_1_reachable and is_alt_2_reachable:
		return alt_2

	if alt_1[0].distance_to(target_position) < alt_2[0].distance_to(target_position):
		return alt_1

	return alt_2

func _detect_jump():
	for raycast in jump_detection_raycasts.get_children():
		if raycast.is_colliding() and _velocity.x != 0:
			jump()

func jump():
	_velocity.y = 2*min_jump_velocity

func _change_direction():
	if move_direction>0:
		_animated_sprite.flip_h = true
		_attack_area.scale.x = -abs(_attack_area.scale.x)
		
		$JumpDetectionRaycasters/JumpDetectionRaycaster.position.x = abs($JumpDetectionRaycasters/JumpDetectionRaycaster.position.x)
		$PlayerDetectionRaycasters/PlayerDetectionRaycaster.cast_to.x = abs($PlayerDetectionRaycasters/PlayerDetectionRaycaster.cast_to.x)
		$PlayerDetectionRaycasters/PlayerDetectionRaycasterBack.cast_to.x = -abs($PlayerDetectionRaycasters/PlayerDetectionRaycasterBack.cast_to.x)
		_attack_detection_area.position.x = abs(_attack_detection_area.position.x)
	elif move_direction < 0:
		_animated_sprite.flip_h = false
		_attack_area.scale.x = abs(_attack_area.scale.x)
		$JumpDetectionRaycasters/JumpDetectionRaycaster.position.x = -abs($JumpDetectionRaycasters/JumpDetectionRaycaster.position.x)
		$PlayerDetectionRaycasters/PlayerDetectionRaycaster.cast_to.x = -abs($PlayerDetectionRaycasters/PlayerDetectionRaycaster.cast_to.x)
		$PlayerDetectionRaycasters/PlayerDetectionRaycasterBack.cast_to.x = abs($PlayerDetectionRaycasters/PlayerDetectionRaycasterBack.cast_to.x)
		_attack_detection_area.position.x = -abs(_attack_detection_area.position.x)
		
func _friction():
	if isDead or isHit:
#		_velocity.x *= 0.8
		_velocity.x = lerp(_velocity.x,0,0.075)



func SightCheck():
	if target_ref:
		target_position = target_ref.get_ref().global_position
		var space_state = get_world_2d().direct_space_state
		var sight_check = space_state.intersect_ray(position, target_position, [self],265)
		if sight_check:
			if sight_check.collider.name == "Player" or sight_check.collider.name == "Undead Executioner":
				player_seen = true
				tracking_player = true
				if !$AlertTimeout.is_stopped():
					$AlertTimeout.stop()
				destination = map_navigation.get_closest_point(target_position)
			else:
				if $AlertTimeout.is_stopped():
					$AlertTimeout.start()
				tracking_player = false
			if tracking_player:
				Search()
				
	else:
		if player_seen == true:
			Return()
			player_seen = false

func _detect_player():
	var target = null
	if !target_ref:
		for raycast in player_detect_raycasts.get_children():
			if raycast.is_colliding():
				target = raycast.get_collider()
				if target.name =="Player" or target.name == "Undead Executioner":
					set_target(target)
					set_alert()

func set_alert():
	if !isAlert:
		isAlert = true
		pop_up_sprite.play("alert")
		_anim_player.play("PopUp")
		$AttackDetectionArea/CollisionShape2D.set_deferred("disabled", false)
		var current_positionX = abs(global_position.x);
		get_tree().call_group("Enemy", "start_detection_timer", current_positionX, target_ref)

func start_detection_timer(x, _target):
	if abs(abs(global_position.x) - x) <= alert_distance: 
		var value = rng.randf_range(0.3, 0.5)
		detection_timer.set_wait_time(value)
		detection_timer.start()
		yield(detection_timer,"timeout")
		set_target(_target)

func damage(amount, knockback_x, knockback_y):
	_health_bar.visible = true
	var damage_taken = amount - _defense * 0.5
	if damage_taken < 1:
		damage_taken=1
	_set_health(health - damage_taken)
	if health != 0:
		emit_signal("hurt")
	knockback(knockback_x, knockback_y)
	_createDamageTakenFloatingText(damage_taken)
	_create_blood()

func _createDamageTakenFloatingText(amount):
	var floaty_text = floaty_text_scene.instance()

#	floaty_text.position = $FloatingTextPosition.position
	floaty_text.position = Vector2(position.x+24,position.y-40)
	floaty_text.velocity = Vector2(rand_range(-50,50),-100)
	floaty_text.modulate = Color(rand_range(0.20, 1), rand_range(0.20, 1), rand_range(0.20, 1), 1.0)
	#orange color
#	floaty_text.modulate = Color(0.9, 0.5, 0.1, 1.0)

	floaty_text.set_text(amount)
	get_tree().get_root().call_deferred("add_child", floaty_text)


func _create_blood():
	var bloody_effect = bloody_scene.instance()
	get_node("Blood").call_deferred("add_child",bloody_effect)

func attack():
	if canAttack:
		isAttacking = true
		_animated_sprite.play("Attack")

func _check_hitboxes():
	if isHit or isDead:
		_attack_hitbox.disabled = true
	if _animated_sprite.animation == "Attack" and _animated_sprite.get_frame() == 4:
			_attack_hitbox.disabled = false
	elif _animated_sprite.animation == "Attack" and _animated_sprite.get_frame() == 6:
		_attack_hitbox.disabled = true

func _on_AttackDetectionArea_body_entered(body):
	canAttack = true

func _on_AttackDetectionArea_body_exited(body):
	yield(_animated_sprite,"animation_finished")
	isAttacking = false
	canAttack = false

func _on_AttackArea_area_entered(area):
	if area.is_in_group("Player_hitbox"):
		var target = area.get_parent()
		var knockback_direction = (target.global_position - global_position).normalized()
		var knockback_x = sign(knockback_direction.x) * knockback_strenght_x
		var knockback_y = sign(knockback_direction.y) * knockback_strenght_y
		var damage_dealt = rng.randi_range(minDamage, maxDamage)
		
		target.damage(damage_dealt, knockback_x, -knockback_strenght_y)

func _on_HeavyBanditSprite_animation_finished():
	if _animated_sprite.animation == "die":
		death_tween.interpolate_callback(self, 2, "disappear")
		death_tween.start()
	if _animated_sprite.animation == "Hurt":
		isHit = false
	if _animated_sprite.animation == "Attack":
		isAttacking = false

func disappear():
	_anim_player.play('Death')

func _on_DetectionTimer_timeout():
	set_alert()

func _on_AlertTimeout_timeout():
	if !isDead:
		set_target(null)
		$AttackDetectionArea/CollisionShape2D.set_deferred("disabled", true)
		isAlert = false
		pop_up_sprite.play("question_mark")
		_anim_player.play("PopUp")

func die():
	set_collision_layer_bit(1, false)
	$HitBox/CollisionShape2D.set_deferred("disabled", true)
	$AttackDetectionArea/CollisionShape2D.set_deferred("disabled", true)
	_health_bar.visible = false
	isDead = true
	PlayerData.xp += experience
	if PlayerData.health != PlayerData.max_health:
		spawn_items(Items.loot.heart,2)
	set_target(null)


func spawn_items(item_scene,amount):
	for Number in amount:
		if rng.randf() <= 0.6:
			var x_direction = rng.randf_range(-50, 50)
			var item = item_scene.instance()
			get_tree().current_scene.call_deferred("add_child", item)
			item.position = global_position
			item.apply_impulse(Vector2(),Vector2(x_direction,-200))

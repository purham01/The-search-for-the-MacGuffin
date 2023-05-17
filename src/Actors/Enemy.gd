extends "res://src/Actors/EnemyClass.gd"
var floaty_text_scene = preload("res://src/Effects/FloatingText.tscn") #ZA OVE PRELOAD NAREDBE PAZI GDI IH STAVLJAŠ JER MOGU STRGAT SVE VARIJABLE I NASLJEĐIVANJA U KLASI
export var experience := 20
export var score: = 100
onready var playernode = get_tree().get_root().find_node("Player",true,false)

func _ready():
	connect("killed",self,"die")
	set_physics_process(false)
	_velocity.x = -move_speed
	
	
func _physics_process(delta):
	_velocity.y += gravity *delta
	if is_on_wall():
		_velocity.x *= -1.0
	_velocity.y = move_and_slide(_velocity, FLOOR_NORMAL).y


func die():
	playernode.add_xp(experience)
	PlayerData.score += score

func damage(amount, knockback_x, knockback_y):
	var damage_taken = amount - _defense * 0.5
	if damage_taken < 1:
		damage_taken=1
	_set_health(health - damage_taken)
	$AnimationPlayer.play("damage")
	knockback(knockback_x, knockback_y)
	_createDamageTakenFloatingText(damage_taken)

func _createDamageTakenFloatingText(amount):
	var floaty_text = floaty_text_scene.instance()
	
	floaty_text.position = Vector2(position.x+50,position.y-120)
	floaty_text.velocity = Vector2(rand_range(-50,50),-100)
	floaty_text.modulate = Color(rand_range(0.20, 1), rand_range(0.20, 1), rand_range(0.20, 1), 1.0)
	#orange color
#	floaty_text.modulate = Color(0.9, 0.5, 0.1, 1.0)

	floaty_text.set_text(amount)
	get_tree().get_root().call_deferred("add_child", floaty_text)

	

func _on_HitBox_body_entered(body):
	if "Player" in body.name:
		var damage_dealt = rng.randi_range(minDamage, maxDamage)
		var knockback_direction = (-global_position + body.global_position).normalized()
		var knockback_x = sign(knockback_direction.x) * knockback_strenght_x
		var knockback_y = sign(knockback_direction.y) * knockback_strenght_y #formula za knockback u zrak ovisno o poziciji lika naspram tebi
		#ako zelis da te knockback uvijek digne u zrak umjesto knockback_y uvrsti -knockback_strenght_y
		#ako zelis direktionalni knockback na y osi uvrsti knockback_y
		#slobodno se igrajte s ovim varijablama
		body.damage(damage_dealt, knockback_x, -knockback_strenght_y)
		



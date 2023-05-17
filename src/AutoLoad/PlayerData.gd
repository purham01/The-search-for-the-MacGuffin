extends Node

signal player_died
signal health_updated(heal)
signal max_health_updated
# warning-ignore:unused_signal
signal xp_updated
signal updated_potions
signal level_up

var deaths = 0 setget set_deaths
var health_potions = 6 setget set_health_potions
var battle_potions = 6 setget set_battle_potions
var ironskin_potions = 6 setget set_ironskin_potions
export var max_health = 250 setget set_max_health
var health = max_health setget set_health

export var damage = 30 setget set_damage
export var defense = 30 setget set_defense
onready var minDamage = round(damage*0.85)
onready var maxDamage = round(damage*1.15)

var xp = 0 setget set_xp
var xp_next_level = 100
var level = 3

var hasPet = true

var save_dict ={
		"health": health,
		"max_health": max_health,
		"level": level,
		"xp": xp,
		"xp_to_next_level": xp_next_level,
		"health_potions": health_potions,
		"battle_potions": battle_potions,
		"ironskin_potions": ironskin_potions,
		"hasPet": hasPet
	}

func save_data():
	save_dict ={
		"health": health,
		"max_health": max_health,
		"level": level,
		"xp": xp,
		"xp_to_next_level": xp_next_level, 
		"health_potions": health_potions,
		"battle_potions": battle_potions,
		"ironskin_potions": ironskin_potions,
		"hasPet": hasPet
	}
	return save_dict

func load_data():
	health_potions = save_dict.health_potions
	battle_potions = save_dict.battle_potions
	ironskin_potions = save_dict.ironskin_potions
	xp = save_dict.xp
	xp_next_level = save_dict.xp_to_next_level
	level = save_dict.level
	health = save_dict.health
	max_health = save_dict.max_health
	hasPet = save_dict.hasPet
	
func reset():
	deaths = 0
	health_potions = 1
	battle_potions = 1
	ironskin_potions = 1
	max_health = 150
	health = max_health
	level = 1
	xp = 0
	xp_next_level = 100
	hasPet = false
	save_data()

func set_deaths(value: int):
	deaths = value
	emit_signal("player_died")

func set_health(value):
	var prev_health = health
	health = clamp(value, 0, max_health)
	if health != prev_health:
		if health < prev_health:
			emit_signal("health_updated",false)
		else:
			emit_signal("health_updated", true)
	
func set_max_health(value):
	max_health = value
	emit_signal("max_health_updated")
	
func set_health_potions(value):
	health_potions = value
	emit_signal("updated_potions")

func set_battle_potions(value):
	battle_potions = value
	emit_signal("updated_potions")

func set_ironskin_potions(value):
	ironskin_potions = value
	emit_signal("updated_potions")

func set_xp(value):
	xp = value
	if xp >= xp_next_level:
		var leftover_xp = xp - xp_next_level
		xp_next_level *= 2
		xp = 0 + leftover_xp
		level += 1
		emit_signal("level_up")
		if leftover_xp>= xp_next_level:
			set_xp(leftover_xp)
	

func set_damage(value):
	damage = value
	minDamage = round(damage*0.85)
	maxDamage = round(damage*1.15)

func set_defense(value):
	defense = value

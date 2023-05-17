extends "res://src/Actors/Actor.gd"

export var _damage = 20
export var _defense = 20
var minDamage
var maxDamage
export (float) var max_health = 100
onready var health = max_health setget _set_health
var target_ref = null setget set_target, get_target

func _set_health(value):
	var prev_health = health
	health = clamp(value, 0, max_health)
	if health != prev_health:
		if health < prev_health:
			emit_signal("health_updated", health)
		if health == 0:
			emit_signal("killed")

func _ready():
	minDamage = round(_damage*0.85)
	maxDamage = round(_damage*1.15)

func set_target(value):
	var prev_ref = target_ref
	if value == null:
		target_ref = null
	elif value is WeakRef:
		target_ref = value
	else:
		target_ref = weakref(value)
	
	_update_target(get_target(target_ref), get_target(prev_ref))
	
func get_target(ref = target_ref):
	var target = null
	if ref is WeakRef:
		target = ref.get_ref()
	return target

func _update_target(new_target, prev_target):
	#if target is previous target then we dont need to update
	if new_target != null and prev_target != null and new_target == prev_target:
		return
	
	#tell the old target we're not targeting it anymore
	if prev_target != null:
		if prev_target.has_method("on_untargeted"):
			prev_target.on_untargeted(self)
	
	#tell the new target that we're targeting it
	if new_target != null:
		if new_target.has_method("on_targeted"):
			new_target.on_targeted(self)

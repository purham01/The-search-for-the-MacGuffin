extends Control

onready var label: Label = get_node("CanvasLayer/Label")

func _ready():
	label.set_text(tr("KEY_STATS") % [PlayerData.deaths,PlayerData.level]) 

func _physics_process(delta):
	$Camera2D.position.x += 20 * delta

extends Node
const TRANS = Tween.TRANS_SINE
const EASE = Tween.EASE_IN_OUT

onready var shake_tween = $ShakeTween
onready var camera = get_parent()

var amplitude = 0
var priority = 0

onready var noise = OpenSimplexNoise.new()
var noise_y = 0

func _ready():
	randomize()
	noise.seed = randi()
	noise.period = 4
	noise.octaves = 2

func start(duration = 0.2, frequency = 15, amplitude = 6, priority = 0):
	if priority >= self.priority:
		self.priority = priority
		self.amplitude = amplitude
	
		
#		rotation = max_roll * amount * noise.get_noise_2d(noise.seed, noise_y)
		
#		offset.y = max_offset.y * amount * noise.get_noise_2d(noise.seed*3, noise_y)

		$Duration.wait_time = duration
		$Frequency.wait_time = 1 / float(frequency)
		$Duration.start()
		$Frequency.start()
		
		_new_shake()

func _new_shake():
	var rand = Vector2()
#	rand.x = rand_range(-amplitude,amplitude)
	noise_y += 1
	rand.x = amplitude * noise.get_noise_2d(noise.seed*2, noise_y)
	
	shake_tween.interpolate_property(camera,"offset", camera.offset, rand, $Frequency.wait_time, TRANS, EASE)
	shake_tween.start()


func _reset():
	shake_tween.interpolate_property(camera,"offset", camera.offset, Vector2(), $Frequency.wait_time, TRANS, EASE)
	shake_tween.start()
	
	priority = 0
	
func _on_Frequency_timeout():
	_new_shake()


func _on_Duration_timeout():
	_reset()
	$Frequency.stop()


func _on_Player_hurt():
	start()

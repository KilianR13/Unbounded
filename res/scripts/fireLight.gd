extends Node3D

@onready var light: OmniLight3D = $light
var base_energy: float = 1.0
var flicker_amount: float = 1.0
var noise: FastNoiseLite = FastNoiseLite.new()
var time_passed: float = 0.0

func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 1.5  # controla la velocidad del cambio
	noise.fractal_octaves = 3  # añade complejidad suave

func _process(delta: float) -> void:
	time_passed += delta
	var flicker: float = noise.get_noise_1d(time_passed) * flicker_amount
	light.light_energy = base_energy + flicker

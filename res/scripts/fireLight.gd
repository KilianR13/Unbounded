extends Node3D

@onready var light: OmniLight3D = $light

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	updateFire()


func updateFire() -> void:
	var fireIntensity: float = randf_range(0.8, 1.2)
	light.light_energy = fireIntensity
	await get_tree().create_timer(0.1).timeout
	updateFire()

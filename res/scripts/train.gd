extends Node3D

@onready var frontLight: SpotLight3D = $frontWagon/SpotLight3D
@onready var backLight: SpotLight3D = $backWagon/SpotLight3D

signal playerHit

@onready var hit_area: Area3D = $playerImpact

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lightOff()


func lightOn() -> void:
	frontLight.visible = true
	backLight.visible = true

func lightOff() -> void:
	frontLight.visible = false
	backLight.visible = false


func _on_player_impact_body_entered(body: Object) -> void:
	if body.is_in_group("player"):
		emit_signal("playerHit")

extends Node3D

@onready var frontLight = $frontWagon/SpotLight3D
@onready var backLight = $backWagon/SpotLight3D

signal playerHit(body)

@onready var hit_area = $playerImpact

# Called when the node enters the scene tree for the first time.
func _ready():
	lightOff()


func lightOn():
	frontLight.visible = true
	backLight.visible = true

func lightOff():
	frontLight.visible = false
	backLight.visible = false


func _on_player_impact_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("playerHit", body)

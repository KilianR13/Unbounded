extends Control

var basePayment: int = CombatManager.levelBaseScore
var obtainedScore: int = CombatManager.levelObtainedScore
var totalScore: int = CombatManager.score

@onready var basePaymentLabel: Label = $VBoxContainer/Control2/VBoxContainer/Control/baseScoreLabel
@onready var extraPaymentLabel: Label = $VBoxContainer/Control2/VBoxContainer/Control2/extraScoreLabel
@onready var totalPaymentLabel: Label = $VBoxContainer/Control2/VBoxContainer/Control3/totalScoreLabel

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	basePaymentLabel.text = "BASE PAYMENT: " + str(basePayment)
	extraPaymentLabel.text = "EXTRA PAYMENT: " + str(obtainedScore)
	totalPaymentLabel.text = "TOTAL PAYMENT: " + str(totalScore)

func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	Global.restartMainMenu = false
	CombatManager.saveScore()
	get_tree().change_scene_to_file("res://res/Scenes/Menus/main_menu.tscn")
	


func _on_try_again_button_pressed() -> void:
	get_tree().change_scene_to_file("res://res/Scenes/World/firstLevel.tscn")

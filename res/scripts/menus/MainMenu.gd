extends Control


var gameStarted: bool = false
@onready var playButton: Button = $VBoxContainerGeneral/Bottom/VBoxContainer/Control/HBoxContainer/ButtonsLeft/VBoxContainerButtons/Play
@onready var gameStartLabel: Label = $VBoxContainerGeneral/Bottom/VBoxContainer/gameStartNode/gameStartLabel
@onready var moneyEarnedLabel: Label = $VBoxContainerGeneral/Bottom/VBoxContainer/gameStartNode/MoneyEarnedLabel

func _ready() -> void:
	if !Global.restartMainMenu:
		Global.restartMainMenu = true
		_game_started()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	var scoreSoFar: int = CombatManager.loadScore()
	moneyEarnedLabel.text = "You've earned " + str(scoreSoFar) + "$ so far."


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	if event is InputEventJoypadMotion:
		return
	
	if event is InputEventKey and event.pressed and !gameStarted:
		_game_started()
	elif event is InputEventMouseButton and event.pressed and !gameStarted:
		_game_started()
	elif event is InputEventJoypadButton and event.pressed and !gameStarted:
		_game_started()


func _game_started() -> void:
	gameStarted = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	gameStartLabel.visible = false
	$AudioStreamPlayer.play()
	playButton.grab_focus()
	$AnimationPlayer.play("startup")
	await get_tree().create_timer(0.5).timeout
	moneyEarnedLabel.visible = true

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://res/Scenes/Menus/loadingScreen.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()

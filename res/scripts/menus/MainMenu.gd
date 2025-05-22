extends Control

var gameStarted: bool = false
@onready var playButton: Button = $VBoxContainerGeneral/Bottom/VBoxContainer/Control/HBoxContainer/ButtonsLeft/VBoxContainerButtons/Play

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


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
	$VBoxContainerGeneral/Bottom/VBoxContainer/gameStartNode.visible = false
	$AudioStreamPlayer.play()
	playButton.grab_focus()
	$AnimationPlayer.play("startup")

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://res/Scenes/Player/loadingScreen.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()

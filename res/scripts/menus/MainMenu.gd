extends Control


var gameStarted: bool = false
var changingOptions: bool
var seeingCredits: bool
@onready var playButton: Button = $VBoxContainerGeneral/Bottom/VBoxContainer/Control/HBoxContainer/ButtonsLeft/VBoxContainerButtons/Play
@onready var gameStartLabel: Label = $VBoxContainerGeneral/Bottom/VBoxContainer/gameStartNode/gameStartLabel
@onready var moneyEarnedLabel: Label = $VBoxContainerGeneral/Bottom/VBoxContainer/gameStartNode/MoneyEarnedLabel

func _ready() -> void:
	changingOptions = false
	seeingCredits = false
	SoundManager.load_settings()
	if !Global.restartMainMenu:
		Global.restartMainMenu = true
		_game_started()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Options.connect("closeOptions", Callable(self, "_closeOptionsMenu"))
	$Credits.connect("closeCredits", Callable(self, "_closeCreditsMenu"))
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
	$MainMenuMusic.play()
	playButton.grab_focus()
	$AnimationPlayer.play("startup")
	await get_tree().create_timer(0.5).timeout
	moneyEarnedLabel.visible = true

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://res/Scenes/Menus/loadingScreen.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_options_pressed() -> void:
	$Options.visible = true
	changingOptions = true

func _closeOptionsMenu() -> void:
	$Options.visible = false
	changingOptions = false

func _closeCreditsMenu() -> void:
	$Credits.visible = false
	seeingCredits = false

func _on_credits_pressed() -> void:
	$Credits.visible = true
	seeingCredits = true

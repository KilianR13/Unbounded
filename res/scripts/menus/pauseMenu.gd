extends Control

signal gameUnpaused

var changingOptions: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	changingOptions = false
	$Options.connect("closeOptions", Callable(self, "_closeOptionsMenu"))
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(_event: InputEvent) -> void:
	if (Input.is_action_just_pressed("pause") || Input.is_action_just_pressed("menuBack")) and !changingOptions:
		toggle_pause()

func toggle_pause() -> void:
	if get_tree().paused:
		# Despausar
		get_tree().paused = false
		visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		$VBoxContainer/Control3/HBoxContainer/Control/resumeButton.grab_focus()
		# Pausar
		get_tree().paused = true
		visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("gameUnpaused")


func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	Global.restartMainMenu = false
	get_tree().change_scene_to_file("res://res/Scenes/Menus/main_menu.tscn")
	

func _closeOptionsMenu() -> void:
	$Options.visible = false
	await get_tree().create_timer(0.1).timeout
	changingOptions = false

func _on_options_menu_pressed() -> void:
	$Options.visible = true
	
	changingOptions = true

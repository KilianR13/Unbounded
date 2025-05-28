extends Control

signal gameUnpaused

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Options.connect("closeOptions", Callable(self, "_closeOptionsMenu"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_resume_button_pressed() -> void:
	emit_signal("gameUnpaused")


func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	Global.restartMainMenu = false
	get_tree().change_scene_to_file("res://res/Scenes/Menus/main_menu.tscn")
	

func _closeOptionsMenu() -> void:
	$Options.visible = false

func _on_options_menu_pressed() -> void:
	$Options.visible = true

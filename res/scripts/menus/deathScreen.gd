extends Control

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = false

func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	Global.restartMainMenu = false
	get_tree().change_scene_to_file("res://res/Scenes/Menus/main_menu.tscn")
	


func _on_try_again_button_pressed() -> void:
	get_tree().change_scene_to_file("res://res/Scenes/World/firstLevel.tscn")

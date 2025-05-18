extends Control

func _ready() -> void:
	$AnimationPlayer.play("startup")


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://res/Scenes/Player/loadingScreen.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()

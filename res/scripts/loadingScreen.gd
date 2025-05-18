extends Control

@onready var nivel1: String = "res://res/Scenes/World/firstLevel.tscn"
@onready var progress_bar: ProgressBar = $VBoxContainer2/Control4/HBoxContainer/Control5/HBoxContainer/Control/VBoxContainer/Control2/ProgressBar
@onready var loadingLabel: Label = $VBoxContainer2/Control4/HBoxContainer/Control5/HBoxContainer/Control/VBoxContainer/Control/Label
@onready var startLevelButton: Button = $VBoxContainer2/Control4/HBoxContainer/Control4/Button

var progress: Array = []
var scene_load_status: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ResourceLoader.load_threaded_request(nivel1)
	await get_tree().create_timer(0.1).timeout
	$loadingMusic.play()

func _process(delta: float) -> void:
	scene_load_status = ResourceLoader.load_threaded_get_status(nivel1, progress)
	progress_bar.value = progress[0] * 100
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		allowButton()

func allowButton() -> void:
	loadingLabel.set_text("Loaded!")
	$VBoxContainer2/Control4/HBoxContainer/Control5/HBoxContainer/Control/VBoxContainer/Control2.visible = false
	$VBoxContainer2/Control4/HBoxContainer/Control5/HBoxContainer/Control/VBoxContainer/Control3.visible = false
	startLevelButton.visible = true

func _on_button_pressed() -> void:
	get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(nivel1))

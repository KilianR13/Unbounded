extends Node

const CONFIG_PATH: String = "user://input_settings.cfg"

var mouse_sensitivity: float = 0.5
var joystick_sensitivity: float = 0.5

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return  # usa valores por defecto

	mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", 0.5)
	joystick_sensitivity = config.get_value("controls", "joystick_sensitivity", 0.5)

func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("controls", "joystick_sensitivity", joystick_sensitivity)
	config.save(CONFIG_PATH)

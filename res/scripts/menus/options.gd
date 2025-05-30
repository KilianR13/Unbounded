extends Control

signal closeOptions

const CONFIG_PATH: String = "user://audio_settings.cfg"
const VIDEO_CONFIG_PATH: String = "user://video_settings.cfg"

const BUS_NAMES: Dictionary = {
	"MasterSlider": "Master",
	"PlayerSFXSlider": "PlayerSFX",
	"EnemySFXSlider": "EnemySFX",
	"MusicSlider": "MusicSFX",
	"WeaponSFXSlider": "GunsSFX",
	"AmbientSFXSlider": "WorldSFX"
}

var resolutions: Array = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

@onready var MasterSlider: HSlider = $MarginContainer/VBoxContainer/ControlOptionsSliders/MarginContainer/TabContainer/Audio/HBoxContainer/ControlLeft/VBoxContainer/Slider1/MarginContainer/VBoxContainer/ControlSlider/MasterSlider
@onready var PlayerSFXSlider: HSlider = $MarginContainer/VBoxContainer/ControlOptionsSliders/MarginContainer/TabContainer/Audio/HBoxContainer/ControlLeft/VBoxContainer/Slider2/MarginContainer/VBoxContainer/ControlSlider/PlayerSFXSlider
@onready var EnemySFXSlider: HSlider = $MarginContainer/VBoxContainer/ControlOptionsSliders/MarginContainer/TabContainer/Audio/HBoxContainer/ControlLeft/VBoxContainer/Slider3/MarginContainer/VBoxContainer/ControlSlider/EnemySFXSlider

@onready var MusicSlider: HSlider = $MarginContainer/VBoxContainer/ControlOptionsSliders/MarginContainer/TabContainer/Audio/HBoxContainer/ControlRight/VBoxContainer/Slider1/MarginContainer/VBoxContainer/ControlSlider/MusicSlider
@onready var WeaponSFXSlider: HSlider = $MarginContainer/VBoxContainer/ControlOptionsSliders/MarginContainer/TabContainer/Audio/HBoxContainer/ControlRight/VBoxContainer/Slider2/MarginContainer/VBoxContainer/ControlSlider/WeaponSFXSlider
@onready var AmbientSFXSlider: HSlider = $MarginContainer/VBoxContainer/ControlOptionsSliders/MarginContainer/TabContainer/Audio/HBoxContainer/ControlRight/VBoxContainer/Slider3/MarginContainer/VBoxContainer/ControlSlider/AmbientSFXSlider

@onready var resolutionOptionButton: OptionButton = $MarginContainer/VBoxContainer/ControlOptionsSliders/MarginContainer/TabContainer/Video/VBoxContainer/VideoOptionTop/HBoxContainer/ControlValue/ResolutionDropdown
@onready var fullScreenCheckBox: CheckBox = $MarginContainer/VBoxContainer/ControlOptionsSliders/MarginContainer/TabContainer/Video/VBoxContainer/VideoOptionBottom/HBoxContainer/ControlOption/FullScreenToggle



func _ready() -> void:
	# Conectar sliders a la función _on_slider_changed
	for slider_name: String in BUS_NAMES.keys():
		var slider: HSlider = get_slider_by_name(slider_name)
		if slider:
			slider.connect("value_changed", Callable(self, "_on_slider_changed").bind(slider_name))
	load_audio_settings()
	
	for res: Vector2i in resolutions:
		resolutionOptionButton.add_item("%dx%d" % [res.x, res.y])
	load_video_settings()
	DisplayServer.window_set_position(Vector2i(0, 0))
	
	
func load_audio_settings() -> void:
	# Carga los valores directamente desde SoundManager y actualiza sliders
	for slider_name: String in BUS_NAMES.keys():
		var bus_name: String = BUS_NAMES[slider_name]
		var slider: HSlider = get_slider_by_name(slider_name)
		if slider:
			# Lee del singleton SoundManager
			slider.value = SoundManager.volumes.get(bus_name, 1.0)

func _on_slider_changed(value: float, slider_name: String) -> void:
	var bus_name: String = BUS_NAMES[slider_name]
	# Actualiza el volumen en SoundManager, que se encargará de limitar al Master y aplicar
	SoundManager.set_volume(bus_name, value)

func on_accept_pressed() -> void:
	# Guardar configuración en disco desde SoundManager
	SoundManager.save_settings()
	save_video_settings()

func get_slider_by_name(name: String) -> HSlider:
	match name:
		"MasterSlider": return MasterSlider
		"PlayerSFXSlider": return PlayerSFXSlider
		"EnemySFXSlider": return EnemySFXSlider
		"MusicSlider": return MusicSlider
		"WeaponSFXSlider": return WeaponSFXSlider
		"AmbientSFXSlider": return AmbientSFXSlider
		_:
			return null

func _on_accept_button_pressed() -> void:
	on_accept_pressed()
	emit_signal("closeOptions")

func _on_cancel_button_pressed() -> void:
	emit_signal("closeOptions")


func _on_full_screen_toggled(pressed: bool) -> void:
	var mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func _on_resolution_selected(index: int) -> void:
	var res: Vector2i = resolutions[index]
	DisplayServer.window_set_size(res)
	DisplayServer.window_set_position(Vector2i(0, 0))

func save_video_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("video", "resolution_index", resolutionOptionButton.selected)
	config.set_value("video", "fullscreen", fullScreenCheckBox.button_pressed)
	config.save(VIDEO_CONFIG_PATH)

func load_video_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(VIDEO_CONFIG_PATH) == OK:
		var index: int = config.get_value("video", "resolution_index", 2)
		var fullscreen: bool = config.get_value("video", "fullscreen", false)
		
		
		resolutionOptionButton.select(index)
		_on_resolution_selected(index)
		
		fullScreenCheckBox.button_pressed = fullscreen
		if fullscreen:
			_on_full_screen_toggled(true)

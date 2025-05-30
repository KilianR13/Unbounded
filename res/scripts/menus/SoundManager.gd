extends Node

const CONFIG_PATH: String = "user://audio_settings.cfg"

const BUS_NAMES: Dictionary = {
	"Master": "Master",
	"PlayerSFX": "PlayerSFX",
	"EnemySFX": "EnemySFX",
	"MusicSFX": "MusicSFX",
	"GunsSFX": "GunsSFX",
	"WorldSFX": "WorldSFX"
}

var volumes: Dictionary = {
	"Master": 0.75,
	"PlayerSFX": 0.5,
	"EnemySFX": 0.5,
	"MusicSFX": 0.5,
	"GunsSFX": 0.5,
	"WorldSFX": 0.5
}

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		apply_volumes()  # Aplica valores por defecto si no hay config
		return

	# Carga valores y limita secundarios al master
	var master_value: float = config.get_value("audio", "Master", 1.0)
	volumes["Master"] = master_value
	for bus_name: String in BUS_NAMES.values():
		var value: float = config.get_value("audio", bus_name, 1.0)
		if bus_name != "Master" and value > master_value:
			value = master_value
		volumes[bus_name] = value

	apply_volumes()

func apply_volumes() -> void:
	for bus_name: String in BUS_NAMES.values():
		var bus_index: int = AudioServer.get_bus_index(bus_name)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volumes[bus_name]))

func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	for bus_name: String in BUS_NAMES.values():
		config.set_value("audio", bus_name, volumes[bus_name])
		config.save(CONFIG_PATH)

func set_volume(bus_name: String, value: float) -> void:
	volumes[bus_name] = value
	if bus_name != "Master":
	# No dejar que volumen secundario supere al master
		if volumes[bus_name] > volumes["Master"]:
			volumes[bus_name] = volumes["Master"]
	else:
		# Ajustar secundarios si master baja
		for key: String in volumes.keys():
			if key != "Master" and volumes[key] > volumes["Master"]:
				volumes[key] = volumes["Master"]
	apply_volumes()

func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

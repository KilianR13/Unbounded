extends Node

signal combat_finished

var active_enemies := 0
var wave_queue := []
var is_spawning := false

func start_wave(enemy_count: int, spawn_func: Callable):
	wave_queue.append({ "count": enemy_count, "spawner": spawn_func })
	_try_start_next_wave()

func _try_start_next_wave():
	if active_enemies == 0 and not is_spawning:
		if wave_queue.is_empty():
			combat_finished.emit()
		else:
			print("Spawneando enemigos")
			var wave = wave_queue.pop_front()
			is_spawning = true
			spawn_wave(wave.count, wave.spawner)

func spawn_wave(count: int, spawn_func: Callable):
	for i in count:
		await get_tree().create_timer(0.1).timeout  # opcional: espaciado
		var enemy = spawn_func.call()
		register_enemy(enemy)
	is_spawning = false
	_try_start_next_wave()

func register_enemy(enemy):
	active_enemies += 1
	enemy.connect("enemy_killed", Callable(self, "_on_enemy_died"))

func _on_enemy_died(_enemy):
	print("enemigo muerto")
	print("Enemigos activos: ",active_enemies)
	active_enemies -= 1
	if active_enemies <= 0:
		_try_start_next_wave()

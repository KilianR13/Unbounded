extends Node

signal combat_finished
signal zombies1_finished
signal updateScore(score: int)

var savePath: String = "user://progress.save"

var active_enemies: int = 0
var active_zombies: int = 0
var wave_queue: Array = []
var is_spawning: bool = false
var score: int = 0
var levelObtainedScore: int
var levelBaseScore: int

func start_wave(enemy_count: int, spawn_func: Callable) -> void:
	wave_queue.append({ "count": enemy_count, "spawner": spawn_func })
	_try_start_next_wave()

func _try_start_next_wave() -> void:
	if active_enemies == 0 and not is_spawning:
		if wave_queue.is_empty():
			combat_finished.emit()
		else:
			var wave: Dictionary = wave_queue.pop_front()
			is_spawning = true
			spawn_wave(wave.count, wave.spawner)

func spawn_wave(count: int, spawn_func: Callable) -> void:
	for i: int in count:
		await get_tree().create_timer(0.1).timeout  # opcional: espaciado
		var enemy: CharacterBody3D = spawn_func.call()
		register_enemy(enemy)
	is_spawning = false
	_try_start_next_wave()

func register_enemy(enemy: CharacterBody3D) -> void:
	active_enemies += 1
	enemy.connect("enemy_killed", Callable(self, "_on_enemy_died"))
	enemy.connect("enemy_headshot", Callable(self, "_headshot_hit"))
	enemy.connect("enemy_killed_with_headshot", Callable(self, "_headshot_kill"))

func _on_enemy_died(_enemy: CharacterBody3D) -> void:
	score += 50
	updateScoreForUI()
	active_enemies -= 1
	if active_enemies <= 0:
		_try_start_next_wave()

## First Zombies
func startFirstFight(AllEnemies: Array) -> void:
	unfreezeEnemies(AllEnemies)
	for enemy: Node in AllEnemies:
		if enemy is CharacterBody3D:
			enemy.scale = Vector3(0.9, 0.9, 0.9)
			active_zombies += 1
			if not enemy.is_connected("enemy_killed", Callable(self, "_on_zombie1_killed")):
				enemy.connect("enemy_killed", Callable(self, "_on_zombie1_killed"))
				enemy.connect("enemy_headshot", Callable(self, "_headshot_hit"))
				enemy.connect("enemy_killed_with_headshot", Callable(self, "_headshot_kill"))
			enemy.anim_tree.set("parameters/conditions/alerted", true)


func unfreezeEnemies(enemies: Array) -> void:
	for enemy: Node in enemies:
		if enemy is CharacterBody3D:
			enemy.set_process(true)
			enemy.set_physics_process(true)
			enemy.visible = true

			if enemy.has_node("Skeleton3D"):
				enemy.get_node("Armature/Skeleton3D").visible = true
			if has_node("AnimationTree"):
				enemy.get_node("AnimationTree").active = true
			if has_node("CollisionShape3D"):
				enemy.get_node("CollisionShape3D").disabled = true

func _on_zombie1_killed() -> void:
	active_zombies -= 1
	score += 20
	updateScoreForUI()
	if active_zombies <= 0:
		await get_tree().create_timer(1.0).timeout
		zombies1_finished.emit()

func startSecondFight(AllEnemies: Array) -> void:
	unfreezeEnemies(AllEnemies)
	for enemy: Node3D in AllEnemies:
		if enemy is CharacterBody3D:
			active_zombies += 1
			if not enemy.is_connected("enemy_killed", Callable(self, "_on_zombie2_killed")):
				enemy.connect("enemy_killed", Callable(self, "_on_zombie2_killed"))
				enemy.connect("enemy_headshot", Callable(self, "_headshot_hit"))
				enemy.connect("enemy_killed_with_headshot", Callable(self, "_headshot_kill"))
			enemy.anim_tree.set("parameters/conditions/alerted", true)

func _on_zombie2_killed() -> void:
	active_zombies -= 1
	score += 20
	updateScoreForUI()

func _headshot_hit() -> void:
	score += 1
	updateScoreForUI()

func _headshot_kill() -> void:
	score += 10
	updateScoreForUI()

func updateScoreForUI() -> void:
	emit_signal("updateScore", score)

func saveScore() -> void:
	var totalScore: int = 0
	if FileAccess.file_exists(savePath):
		var checkFile: FileAccess = FileAccess.open(savePath, FileAccess.READ)
		if checkFile != null and checkFile.get_length() >= 4:
			totalScore = checkFile.get_var()
		checkFile.close()
	totalScore += score
	var file: FileAccess = FileAccess.open(savePath, FileAccess.WRITE)
	file.store_var(totalScore)
	file.close()

func loadScore() -> int:
	var returnValue: int = 0
	if FileAccess.file_exists(savePath):
		var file: FileAccess  = FileAccess.open(savePath, FileAccess.READ)
		returnValue = file.get_var(score)
		file.close()
	return returnValue


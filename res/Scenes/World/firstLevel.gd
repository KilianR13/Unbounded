extends Node3D

@onready var player : CharacterBody3D = $Player
@onready var playerSpawn: Node3D = $playerSpawnPoint
@onready var firstDoorAnimation: AnimationPlayer = $specialOcclusionNodes/firstDoor/doorOpenAnimation
@onready var firstDoorSound: AudioStreamPlayer3D = $specialOcclusionNodes/firstDoor/doorOpenSound

@onready var trainDoorAnimation1: AnimationPlayer = $LevelGeometry/SecondZone/TrainTransitionZone/TrainDoors/AnimationPlayer
@onready var trainWaitTimer: Timer = $LevelGeometry/SecondZone/TrainTransitionZone/TrainDoors/trainWaitTimer
@onready var trainPassTimer: Timer = $LevelGeometry/SecondZone/TrainTransitionZone/TrainDoors/trainPassTimer
@onready var train: Node3D = $LevelGeometry/SecondZone/TrainTransitionZone/train/train
@onready var train3DDestiny: Node3D = $LevelGeometry/SecondZone/TrainTransitionZone/train/trainDestiny
@onready var trainSFX: AudioStreamPlayer3D = $LevelGeometry/SecondZone/TrainTransitionZone/train/trainSFX
@onready var NormalMusic: AudioStreamPlayer = $Music/RegularMusic
@onready var CombatMusicBuildup: AudioStreamPlayer = $Music/CombatBuildup
@onready var CombatMusicAction: AudioStreamPlayer = $Music/CombatMusic
var combatActive: bool
var currentZombies: int = 0
var payment: int = 800

var reverse_mode: bool = false
var trainSpeed: float = 100.0
var posicion_inicial_tren : Vector3
var posicion_objetivo_tren : Vector3
var tween: Tween

@onready var zombieEnemy: PackedScene = preload("res://res/Scenes/Enemies/zombie_enemy.tscn")
@onready var mutantEnemy: PackedScene = preload("res://res/Scenes/Enemies/mutant_enemy.tscn")
@onready var mutantSpawnArea: Area3D = $combat_logic/zone3/mutantSpawner/Area3D
@onready var mutantSpawnShape: CollisionShape3D = $combat_logic/zone3/mutantSpawner/Area3D/CollisionShape3D
@onready var zombiesFloor1: Array = $combat_logic/FirstZoneZombies/FirstFloor.get_children()
@onready var zombiesFloor2: Array = $combat_logic/FirstZoneZombies/FirstFloorInside.get_children()


var firstDoorOpen:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	freezeEnemies(zombiesFloor1)
	freezeEnemies(zombiesFloor2)
	CombatManager.clear_zombies()
	CombatManager.add_zombie(zombiesFloor1)
	CombatManager.add_zombie(zombiesFloor2)
	
	player.global_position = playerSpawn.global_position
	trainWaitTimer.start()
	posicion_inicial_tren = train.global_position
	posicion_objetivo_tren = train3DDestiny.global_position
	train.connect("playerHit", Callable(self,"playerDeathInLevel"))
	CombatManager.score = 0
	CombatManager.updateScoreForUI()
	CombatManager.active_enemies = 0
	CombatManager.active_zombies = 0
	if not CombatManager.is_connected("zombies1_finished", Callable(self, "_triggerSecondZombieCombat")):
		CombatManager.connect("zombies1_finished", Callable(self, "_triggerSecondZombieCombat"))
	player.connect("playerDeathEnviroment", Callable(self, "stopMusicFromDeath"))
	

func trainPass() -> void:
	var distancia: float = posicion_inicial_tren.distance_to(posicion_objetivo_tren)
	var duracion: float = distancia / trainSpeed

	tween = get_tree().create_tween()
	tween.tween_property(train, "global_position", posicion_objetivo_tren, duracion)
	tween.tween_callback(Callable(self, "_on_train_destiny"))

func _on_train_destiny() -> void:
	train.lightOff()
	train.global_position = posicion_inicial_tren


func openFirstDoor() -> void:
	firstDoorAnimation.play("doorOpen")
	firstDoorSound.play()
	firstDoorOpen = true

func _on_killzone_area_body_entered(body: Object) -> void:
	if body.is_in_group("player"):
		playerDeathInLevel()
		

func playerDeathInLevel() -> void:
	if player.isAlive:
		stopMusicFromDeath()
		player.playerDeath()

func stopMusicFromDeath() -> void:
	if player.isAlive:
		NormalMusic.stop()
		CombatMusicBuildup.stop()
		CombatMusicAction.stop()

func _on_train_wait_timer_timeout()  -> void:
	trainWaitTimer.set_wait_time(24.0)
	reverse_mode = false
	trainDoorAnimation1.play("openDoorTrain")


func _on_animation_player_animation_finished(anim_name: String)  -> void:
	if anim_name == "openDoorTrain":
		if !reverse_mode:
			trainWaitTimer.stop()
			trainPass()
			train.lightOn()
			trainSFX.play()
			trainPassTimer.start()


func _on_train_pass_timer_timeout() -> void:
	reverse_mode = true
	trainDoorAnimation1.play_backwards("openDoorTrain")
	trainWaitTimer.start()

# ENEMY SPAWN LOGIC
func spawnMutant() -> CharacterBody3D:
	var pos: Vector3 = get_random_position_spawn()
	var enemy: CharacterBody3D = mutantEnemy.instantiate()
	enemy.scale = Vector3(1.75, 1.75, 1.75)
	enemy.player_path = player.get_path()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = pos
	return enemy


func get_random_position_spawn() -> Vector3:
	var box: BoxShape3D = mutantSpawnShape.shape as BoxShape3D
	var extents: Vector3 = box.size/2
	var random_x: float = randf_range(-extents.x, extents.x)
	var random_y: float = 0.0
	var random_z: float = randf_range(-extents.z, extents.z)
	var origin: Vector3 = mutantSpawnArea.global_transform.origin
	return origin + Vector3(random_x, random_y, random_z)


func _on_mutant_trigger_body_entered(body: Object) -> void:
	if body.is_in_group("player"):
		CombatManager.reset()
		CombatMusicBuildup.play()
		combatActive = true
		CombatManager.clear_zombies()
		var musicTween: Tween = get_tree().create_tween()
		musicTween.tween_property(NormalMusic, "volume_db", -80, 2.0)
		musicTween.tween_callback(Callable(NormalMusic, "stop"))
		
		$combat_logic/zone3/mutantSpawner/mutantTrigger.set_deferred("monitoring", false)
		CombatManager.start_wave(10, "spawnMutant", get_path())
		CombatManager.start_wave(30, "spawnMutant", get_path())
		CombatManager.start_wave(50, "spawnMutant", get_path())
		CombatManager.connect("combat_finished", Callable(self, "_on_combat_finished"))

func _on_combat_finished() -> void:
	combatActive = false
	stageFinished()
	var musicTween: Tween = get_tree().create_tween()
	if CombatMusicAction.is_playing():
		musicTween.tween_property(CombatMusicAction, "volume_db", -80, 6.0) # 2 segundos de fade
		musicTween.tween_callback(Callable(CombatMusicAction, "stop"))
		musicTween.tween_property(CombatMusicAction, "volume_db", -8, 0)
	elif CombatMusicBuildup.is_playing():
		musicTween.tween_property(CombatMusicBuildup, "volume_db", -80, 2.0) # 2 segundos de fade
		musicTween.tween_callback(Callable(CombatMusicBuildup, "stop"))
		musicTween.tween_property(CombatMusicBuildup, "volume_db", -8, 0)

func _on_combat_buildup_finished() -> void:
	if combatActive:
		CombatMusicAction.play()

func _on_first_zombie_trigger_body_entered(body: Object) -> void:
	if body.is_in_group("player"):
		$combat_logic/FirstZoneZombies/FirstFloor/FirstZombieTrigger.set_deferred("monitoring", false)
		#var zombiesFloor1: Array = $combat_logic/FirstZoneZombies/FirstFloor.get_children()
		CombatManager.startFirstFight(zombiesFloor1)
		

func _triggerSecondZombieCombat() -> void:
	#var zombiesFloor2: Array = $combat_logic/FirstZoneZombies/FirstFloorInside.get_children()
	openFirstDoor()
	CombatManager.startSecondFight(zombiesFloor2)

func freezeEnemies(enemies: Array) -> void:
	for enemy: Node in enemies:
		if enemy is CharacterBody3D:
			enemy.scale = Vector3(0.9, 0.9, 0.9)
			enemy.set_process(false)
			enemy.set_physics_process(false)
			enemy.visible = false
			if enemy.has_node("Skeleton3D"):
				enemy.get_node("Armature/Skeleton3D").visible = false
			if has_node("AnimationTree"):
				enemy.get_node("AnimationTree").active = false
			if has_node("CollisionShape3D"):
				enemy.get_node("CollisionShape3D").disabled = true
			enemy.canBeDamaged = false

func stageFinished() -> void:
	CombatManager.levelObtainedScore = CombatManager.score
	CombatManager.score += payment
	CombatManager.levelBaseScore = payment
	await get_tree().create_timer(8.0).timeout
	get_tree().change_scene_to_file("res://res/Scenes/Menus/victoryScreen.tscn")

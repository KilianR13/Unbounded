extends Node3D

@onready var player = $Player
@onready var playerSpawn = $playerSpawnPoint
@onready var secondSpawnTest = $secondSpawnPoint
@onready var firstDoorAnimation = $FirstZone/Decoration/playableBuilding1/level0/firstDoor/doorOpenAnimation
@onready var firstDoorSound = $FirstZone/Decoration/playableBuilding1/level0/firstDoor/doorOpenSound

@onready var trainDoorAnimation1 = $SecondZone/TrainTransitionZone/TrainDoors/AnimationPlayer
@onready var trainWaitTimer = $SecondZone/TrainTransitionZone/TrainDoors/trainWaitTimer
@onready var trainPassTimer = $SecondZone/TrainTransitionZone/TrainDoors/trainPassTimer
@onready var train = $SecondZone/TrainTransitionZone/train/train
@onready var train3DDestiny = $SecondZone/TrainTransitionZone/train/trainDestiny
@onready var trainSFX = $SecondZone/TrainTransitionZone/train/trainSFX
@onready var CombatMusicBuildup = $Node3D/CombatBuildup
@onready var CombatMusicAction = $Node3D/CombatMusic
var combatActive


var reverse_mode = false
var trainSpeed = 100.0
var posicion_inicial_tren : Vector3
var posicion_objetivo_tren : Vector3
var tween: Tween

@onready var mutantEnemy = preload("res://res/Scenes/Enemies/mutant_enemy.tscn")
@onready var mutantSpawnArea = $combat_logic/zone3/mutantSpawner/Area3D
@onready var mutantSpawnShape = $combat_logic/zone3/mutantSpawner/Area3D/CollisionShape3D

var firstDoorOpen:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	#player.global_position = playerSpawn.global_position
	player.global_position = secondSpawnTest.global_position
	trainWaitTimer.start()
	posicion_inicial_tren = train.global_position
	posicion_objetivo_tren = train3DDestiny.global_position
	train.playerHit.connect(death)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func trainPass():
	var distancia = posicion_inicial_tren.distance_to(posicion_objetivo_tren)
	var duracion = distancia / trainSpeed

	tween = get_tree().create_tween()
	tween.tween_property(train, "global_position", posicion_objetivo_tren, duracion)
	tween.tween_callback(Callable(self, "_on_train_destiny"))

func _on_train_destiny():
	train.lightOff()
	train.global_position = posicion_inicial_tren

func _on_area_3d_body_entered(body):
	if body.is_in_group("player") and !firstDoorOpen:
		firstDoorAnimation.play("doorOpen")
		firstDoorSound.play()
		firstDoorOpen = true


func _on_killzone_area_body_entered(body):
	if body.is_in_group("player"):
		#player.playerDeath()
		death(body) #TEMP


func _on_train_wait_timer_timeout():
	trainWaitTimer.set_wait_time(24.0)
	reverse_mode = false
	trainDoorAnimation1.play("openDoorTrain")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "openDoorTrain":
		if !reverse_mode:
			trainWaitTimer.stop()
			trainPass()
			train.lightOn()
			trainSFX.play()
			trainPassTimer.start()

func death(_body):
	player.global_position = secondSpawnTest.global_position # TEMP

func _on_train_pass_timer_timeout():
	reverse_mode = true
	trainDoorAnimation1.play_backwards("openDoorTrain")
	trainWaitTimer.start()

# ENEMY SPAWN LOGIC
func spawnMutant():
	var pos = get_random_position_spawn()
	var enemy = mutantEnemy.instantiate()
	enemy.scale = Vector3(1.75, 1.75, 1.75)
	enemy.player_path = player.get_path()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = pos
	return enemy

func spawnZombie():
	var pos = get_random_position_spawn()
	var enemy = mutantEnemy.instantiate()
	enemy.scale = Vector3(1.75, 1.75, 1.75)
	enemy.player_path = player.get_path()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = pos
	return enemy

func get_random_position_spawn():
	var box = mutantSpawnShape.shape as BoxShape3D
	var extents = box.size/2
	var random_x = randf_range(-extents.x, extents.x)
	var random_y = 0
	var random_z = randf_range(-extents.z, extents.z)
	var origin = mutantSpawnArea.global_transform.origin
	return origin + Vector3(random_x, random_y, random_z)


func _on_mutant_trigger_body_entered(body):
	if body.is_in_group("player"):
		CombatMusicBuildup.play()
		combatActive = true
		$combat_logic/zone3/mutantSpawner/mutantTrigger.set_deferred("monitoring", false)
		CombatManager.start_wave(10, func(): return spawnMutant())
		CombatManager.start_wave(20, func(): return spawnMutant())
		CombatManager.connect("combat_finished", Callable(self, "_on_combat_finished"))

func _on_combat_finished():
	combatActive = false
	var tween := get_tree().create_tween()
	if CombatMusicAction.is_playing():
		tween.tween_property(CombatMusicAction, "volume_db", -80, 6.0) # 2 segundos de fade
		tween.tween_callback(Callable(CombatMusicAction, "stop"))
		tween.tween_property(CombatMusicAction, "volume_db", -8, 0)
	elif CombatMusicBuildup.is_playing():
		tween.tween_property(CombatMusicBuildup, "volume_db", -80, 2.0) # 2 segundos de fade
		tween.tween_callback(Callable(CombatMusicBuildup, "stop"))
		tween.tween_property(CombatMusicBuildup, "volume_db", -8, 0)

func _on_combat_buildup_finished():
	if combatActive:
		CombatMusicAction.play()

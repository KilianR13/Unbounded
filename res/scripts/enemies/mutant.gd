extends CharacterBody3D

signal enemy_killed
signal enemy_killed_with_headshot
signal enemy_headshot

var player: CharacterBody3D = null

const SPEED: float = 7.0
const ATTACK_DETECTION_RANGE: int = 3
var health: int = 10
var playerDamage: int = 20
var dead: bool = false
var rotated: bool = false
var can_attack: bool = true
var state_machine: AnimationNodeStateMachinePlayback


@export var player_path: NodePath

@onready var navAgent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var generalCollisionShape: CollisionShape3D = $CollisionShape3D

var cached_player_position : Vector3 = Vector3.ZERO
var ai_update_interval: float = 0.2  # segundos
var ai_offset: float = 0.0

func _ready() -> void:
	player = get_node(player_path)
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	state_machine = anim_tree.get("parameters/playback")
	ai_offset = randf_range(0.0, ai_update_interval)
	set_physics_process(false)
	call_deferred("dump_first_physics_frame")


func dump_first_physics_frame() -> void:
	await get_tree().physics_frame
	set_physics_process(true)
	update_ai_loop()

func update_ai_loop() -> void:
	while not dead:
		if player.isAlive:
			_update_ai_logic()
		await get_tree().create_timer(ai_update_interval + ai_offset).timeout
		if !is_inside_tree() or is_queued_for_deletion():
			break

func _physics_process(_delta: float) -> void:
	if dead:
		return
	
	if _target_in_range() and can_attack:
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		can_attack = false
		anim_tree.set("parameters/conditions/attack", true)
		await get_tree().create_timer(0.1).timeout  # pequeño delay para asegurar la transición
		anim_tree.set("parameters/conditions/attack", false)
		await get_tree().create_timer(0.1).timeout
		can_attack = true
	else:
		anim_tree.set("parameters/conditions/chase", true)		
	move_and_slide()
	
func _update_ai_logic() -> void:
	cached_player_position = player.global_transform.origin
	match state_machine.get_current_node():
		"runAnimation":
			navAgent.set_target_position(cached_player_position)
			var nextNavPoint: Vector3 = navAgent.get_next_path_position()
			var to_point: Vector3 = nextNavPoint - global_transform.origin
			
			var horizontal_dir: Vector3 = to_point
			horizontal_dir.y = 0
			if horizontal_dir.length() > 0.01:
				look_at(global_transform.origin + horizontal_dir, Vector3.UP)
			
			if to_point.length() > 0.1:
				velocity = to_point.normalized() * SPEED
			else:
				velocity = Vector3.ZERO
		"attackAnimation":
			velocity = Vector3.ZERO

func _target_in_range() -> bool:
	return global_position.distance_to(player.global_position) < ATTACK_DETECTION_RANGE

func receive_hit(damage: int, headshotMultiplier: int, is_headshot : bool) -> void:
	if is_headshot:
		damage *= headshotMultiplier
		emit_signal("enemy_headshot")
	health -= damage
	if health <= 0:
		if !dead:
			disable_enemy_areas_local()
			emit_signal("enemy_killed", self)
		dead = true # Detiene el movimiento del enemigo.
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		var randomPitch: float = rng.randf_range(0.75, 1.0)
		var deathSound: AudioStreamPlayer3D = $deathSFX
		deathSound.set_pitch_scale(randomPitch)
		deathSound.play()
		if is_headshot:
			emit_signal("enemy_killed_with_headshot")
		generalCollisionShape.disabled = true
		if state_machine:
			state_machine.travel("deathAnimation")
		anim_tree.set("parameters/conditions/die", true)
		await get_tree().create_timer(8.0).timeout # La animación dura 8 segundos.
		queue_free()

func disable_enemy_areas_local() -> void:
	for child: Node in get_children():
		_disable_areas_recursive(child)

func _disable_areas_recursive(node: Node) -> void:
	if node is Area3D and node.is_in_group("enemy"):
		node.remove_from_group("enemy")
	if node is CollisionShape3D:
		node.disabled = true
	for subnode: Node in node.get_children():
		_disable_areas_recursive(subnode)

func dealDamage() -> void:
	if global_position.distance_to(player.global_position) < ATTACK_DETECTION_RANGE + 1.0:
		player.recieve_hit(playerDamage)

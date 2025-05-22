extends CharacterBody3D

signal enemy_killed
signal enemy_killed_with_headshot
signal enemy_headshot

var player: CharacterBody3D = null

const SPEED: float = 7.0
const ATTACK_DETECTION_RANGE: int = 3
var health: int = 10
var dead: bool = false
var rotated: bool = false
var state_machine: AnimationNodeStateMachinePlayback


@export var player_path: NodePath

@onready var navAgent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var generalCollisionShape: CollisionShape3D = $CollisionShape3D

var cached_player_position : Vector3 = Vector3.ZERO

func _ready() -> void:
	player = get_node(player_path)
	state_machine = anim_tree.get("parameters/playback")
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
		await get_tree().create_timer(0.5).timeout

func _physics_process(_delta: float) -> void:
	if dead:
		return
	move_and_slide()
	
func _update_ai_logic() -> void:
	cached_player_position = player.global_transform.origin
	match state_machine.get_current_node():
		"runAnimation":
			anim_tree.root_motion_track = "Armature/Skeleton3D:mixamorig_Hips"
			navAgent.set_target_position(cached_player_position)
			var nextNavPoint: Vector3 = navAgent.get_next_path_position()
			velocity = (nextNavPoint - global_transform.origin).normalized() * SPEED
		"attackAnimation":
			velocity = Vector3.ZERO
			anim_tree.root_motion_track = ""
	look_at(Vector3(cached_player_position.x, global_position.y, cached_player_position.z), Vector3.UP)
	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/chase", !_target_in_range())

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
		if is_headshot:
			emit_signal("enemy_killed_with_headshot")
		anim_tree.root_motion_track = "" # Quita el root motion para que la animación funcione bien.
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

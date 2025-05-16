extends CharacterBody3D

signal enemy_killed

var player = null

const SPEED = 3.0
const ATTACK_DETECTION_RANGE = 1
var health = 1000
var dead = false
var rotated = false
var state_machine


@export var player_path: NodePath
@export var activate: bool = true

@onready var navAgent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
@onready var generalCollisionShape = $CollisionShape3D
@onready var tween: Tween

var ai_update_interval : int = 2  # Número de fotogramas entre cada actualización de la IA
var ai_update_counter : int = 0  # Contador de fotogramas

func _ready():
	anim_tree.set("parameters/conditions/alerted", true)
	player = get_node(player_path)
	state_machine = anim_tree.get("parameters/playback")
	set_physics_process(false)
	call_deferred("dump_first_physics_frame")


func dump_first_physics_frame() -> void:
	await get_tree().physics_frame
	set_physics_process(true)


func _physics_process(_delta):
	if activate and !dead:
		ai_update_counter += 1
		
		if ai_update_counter >= ai_update_interval:
		#if 0 == 0:
			#print("Zombie velocity: ", velocity)
			ai_update_counter = 0  
			velocity = Vector3.ZERO
			match state_machine.get_current_node():
				"runAnimation":
					# NAVIGATION
					anim_tree.root_motion_track = "Armature/Skeleton3D:mixamorig_Hips"
					navAgent.set_target_position(player.global_transform.origin)
					var nextNavPoint = navAgent.get_next_path_position()
					velocity = (nextNavPoint - global_transform.origin).normalized() * SPEED
					look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
				"attackAnimation":
					anim_tree.root_motion_track = ""
					look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
			move_and_slide()
		anim_tree.set("parameters/conditions/attack", _target_in_range())
		anim_tree.set("parameters/conditions/run", !_target_in_range())
		

func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_DETECTION_RANGE

func receive_hit(damage, headshotMultiplier, is_headshot = false):
	print("Golpe")
	if is_headshot:
		damage *= headshotMultiplier
	health -= damage
	if health <= 0:
		if !dead:
			disable_enemy_areas_local()
			emit_signal("enemy_killed", self)
		dead = true # Detiene el movimiento del enemigo.
		generalCollisionShape.disabled = true
		anim_tree.root_motion_track = "" # Quita el root motion para que la animación funcione bien.
		anim_tree.set("parameters/conditions/die", true)
		await get_tree().create_timer(8.0).timeout # La animación dura 8 segundos.
		queue_free()

func disable_enemy_areas_local():
	for child in get_children():
		_disable_areas_recursive(child)

func _disable_areas_recursive(node):
	if node is Area3D and node.is_in_group("enemy"):
		node.remove_from_group("enemy")
	if node is CollisionShape3D:
		node.disabled = true
	for subnode in node.get_children():
		_disable_areas_recursive(subnode)

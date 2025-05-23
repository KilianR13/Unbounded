extends Node3D

var damage: int = 5
var critMultiplier: int = 2
var maxAmmo: int = 100
var reloaded: bool = true

@export var pellets: int = 8
@export var spread_angle_deg: float = 6.0
@export var explosionRange: float = 50.0

signal shotFinished
signal criticalHit(superCharge: int)

@onready var fogonazoLight: OmniLight3D = $RootNode/fogonazoLight
@onready var fogonazoSpotLight: SpotLight3D = $RootNode/fogonazoSpotLight
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var shootSound: AudioStreamPlayer = $ShootSFX
@onready var barrelPos: Node3D = $RootNode/Barrel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fogonazoLight.visible = false
	fogonazoSpotLight.visible = false
	

func shoot(raycast: RayCast3D) -> void:
	if animationPlayer.is_playing():
		return 
	
	animationPlayer.play("shoot")
	reloaded = false
	fogonazo()
	shootSound.play()
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var origin: Vector3 = barrelPos.global_transform.origin
	var forward: Vector3 = -barrelPos.global_transform.basis.z.normalized()

	for i: int in pellets:
		var direction: Vector3 = get_random_spread_vector(forward, spread_angle_deg)
		var to: Vector3 = origin + direction * explosionRange
		var ray_params: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, to)
		ray_params.collision_mask = 1 << 2
		ray_params.collide_with_bodies = false
		ray_params.collide_with_areas = true
		ray_params.exclude = [self]
		
		var result: Dictionary = space_state.intersect_ray(ray_params)
		
		if result:
			var collider: Object = result["collider"]
			if collider.is_in_group("enemy"):
				var enemy_node: CharacterBody3D = collider.get_owner()
				var is_headshot: bool = collider.is_in_group("enemy_head")
				enemy_node.receive_hit(damage, critMultiplier, is_headshot)
				var hit_position: Vector3 = result["position"]
				var blood_fx: GPUParticles3D = preload("res://res/Scenes/Player/bloodSplatter.tscn").instantiate()
				get_tree().current_scene.add_child(blood_fx)
				blood_fx.trigger(hit_position, barrelPos.global_position)
				if is_headshot:
					emit_signal("criticalHit", 5)
	raycast.enabled = false
	emit_signal("shotFinished")

func get_random_spread_vector(base_dir: Vector3, max_angle_deg: float) -> Vector3:
	var angle_rad: float = deg_to_rad(max_angle_deg)
	var rot: Basis = Basis()
	rot = rot.rotated(Vector3.UP, randf_range(-angle_rad, angle_rad))
	rot = rot.rotated(Vector3.RIGHT, randf_range(-angle_rad, angle_rad))
	return (rot * base_dir).normalized()


func checkForReload() -> void:
	if !reloaded:
		_reload()

func fogonazo() -> void:
	fogonazoLight.visible = true
	fogonazoSpotLight.visible = true
	await get_tree().create_timer(0.1).timeout
	fogonazoLight.visible = false
	fogonazoSpotLight.visible = false


func _reload() -> void:
	animationPlayer.play("reload")
	$ReloadSFX.play()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "shoot":
		_reload()
	if anim_name == "reload":
		reloaded = true

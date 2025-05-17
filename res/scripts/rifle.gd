extends Node3D

var damage: int = 2
var critMultiplier: int = 2
var maxAmmo: int = 300

signal shotFinished
signal criticalHit(superCharge: int)

@onready var fogonazoLight: OmniLight3D = $RootNode/fogonazoLight
@onready var fogonazoSpotLight: SpotLight3D = $RootNode/fogonazoSpotLight
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var shootSound: AudioStreamPlayer = $gunshot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	fogonazoLight.visible = false
	fogonazoSpotLight.visible = false


func shoot(raycast: RayCast3D) -> void:
	animationPlayer.play("shoot")
	fogonazo()
	shootSound.play()
	raycast.enabled = true
	raycast.force_raycast_update()
	
	
	if raycast.is_colliding():
		var collider: Object = raycast.get_collider()
		if collider.is_in_group("enemy"):
			var enemy_node: CharacterBody3D = collider.get_owner()
			var is_headshot: bool = collider.is_in_group("enemy_head")
			enemy_node.receive_hit(damage, critMultiplier, is_headshot)
			var hit_position: Vector3 = raycast.get_collision_point()
			var blood_fx: GPUParticles3D = preload("res://res/Scenes/Player/bloodSplatter.tscn").instantiate()
			get_tree().current_scene.add_child(blood_fx)
			blood_fx.trigger(hit_position, self.global_position)
			if is_headshot:
				emit_signal("criticalHit", 5)
	raycast.enabled = false
	emit_signal("shotFinished")

func fogonazo() -> void:
	fogonazoLight.visible = true
	fogonazoSpotLight.visible = true
	await get_tree().create_timer(0.07).timeout
	fogonazoLight.visible = false
	fogonazoSpotLight.visible = false

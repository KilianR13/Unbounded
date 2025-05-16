extends Node3D

var damage = 5
var critMultiplier = 2
var maxAmmo = 100
var rng = RandomNumberGenerator.new()

signal shotFinished
signal criticalHit(superCharge)

@onready var fogonazoLight = $RootNode/fogonazoLight
@onready var fogonazoSpotLight = $RootNode/fogonazoSpotLight
@onready var animationPlayer = $AnimationPlayer
@onready var shootSound = $gunshot
@onready var barrelPos = $RootNode/Barrel


# Called when the node enters the scene tree for the first time.
func _ready():
	fogonazoLight.visible = false
	fogonazoSpotLight.visible = false


func shoot(raycast: RayCast3D):
	if !animationPlayer.is_playing():
		animationPlayer.play("shoot")
		fogonazo()
		var randomPitch = rng.randf_range(0.75, 0.8)
		shootSound.set_pitch_scale(randomPitch)
		shootSound.play()
		raycast.enabled = true
		raycast.force_raycast_update()
		
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.is_in_group("enemy"):
				var enemy_node = collider.get_owner()
				var is_headshot = collider.is_in_group("enemy_head")
				enemy_node.receive_hit(damage, critMultiplier, is_headshot)
				var hit_position = raycast.get_collision_point()
				var blood_fx = preload("res://res/Scenes/Player/bloodSplatter.tscn").instantiate()
				get_tree().current_scene.add_child(blood_fx)
				blood_fx.trigger(hit_position, barrelPos.global_position)
				if is_headshot:
					emit_signal("criticalHit", 5)
		raycast.enabled = false
		emit_signal("shotFinished")


func fogonazo():
	fogonazoLight.visible = true
	fogonazoSpotLight.visible = true
	await get_tree().create_timer(0.1).timeout
	fogonazoLight.visible = false
	fogonazoSpotLight.visible = false

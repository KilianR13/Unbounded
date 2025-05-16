extends Node3D

@export var damage = 20
@export var critMultiplier = 3
@export var superCharge = 0

signal shotFinished
signal criticalHit(superCharge)

@onready var animationPlayer = $AnimationPlayer
@onready var fogonazoLight = $RootNode/fogonazoLight
@onready var fogonazoSpotLight = $RootNode/fogonazoSpotLight
@onready var gunshot = $gunshotSFX

func _ready():
	fogonazoLight.visible = false
	fogonazoSpotLight.visible = false


func shoot(raycast):
	if !animationPlayer.is_playing():
		animationPlayer.play("shoot")
		gunshot.play()
		fogonazo()
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
				blood_fx.trigger(hit_position, self.global_position)
				if is_headshot:
					emit_signal("criticalHit", 0)
		raycast.enabled = false
		fogonazo()
		emit_signal("shotFinished")

func fogonazo():
	fogonazoLight.visible = true
	fogonazoSpotLight.visible = true
	await get_tree().create_timer(0.1).timeout
	fogonazoLight.visible = false
	fogonazoSpotLight.visible = false

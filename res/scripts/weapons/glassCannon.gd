extends Node3D

var damage: int = 10
var critMultiplier: int = 1
var maxAmmo: int = 10

signal shotFinished
signal criticalHit(superCharge: int)

@onready var body_mesh: MeshInstance3D = $GlassCannon/group1777393000
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var chargeSound: AudioStreamPlayer = $ChargeSFX
@onready var shootSound: AudioStreamPlayer = $ShootSFX
var original_color: Color = Color(0.922, 0.949, 0.941, 0.4)
var target_color: Color = Color(0.922, 0.949, 0.1, 0.4)
var color_duration: float = 2.49
var material_index: int = 0
var standard_mat: StandardMaterial3D
var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mat: Material = body_mesh.mesh.surface_get_material(material_index)
	if mat is StandardMaterial3D:
		standard_mat = mat.duplicate() as StandardMaterial3D
		body_mesh.mesh.surface_set_material(material_index, standard_mat)



func shoot(raycast: RayCast3D) -> void:
	if animationPlayer.is_playing():
		return 
	
	_chargeCannon()
	animationPlayer.play("chargeShot")
	chargeSound.play()
	await get_tree().create_timer(2.49).timeout
	_real_shoot(raycast)

	# Ahora reproducimos la animación shoot y sonido de disparo
	animationPlayer.play("shoot")
	shootSound.play()

func _chargeCannon() -> void:
	if standard_mat:
		
		#print("Tween started at time:", Time.get_ticks_msec())
		#standard_mat.emission_enabled = true
		# Si hay un tween corriendo, lo matamos
		if tween and tween.is_running():
			tween.kill()

		tween = create_tween()
		tween.tween_property(standard_mat, "emission", target_color, color_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_interval(0.01)
		tween.tween_property(standard_mat, "emission", target_color, 0.0)

func _real_shoot(raycast: RayCast3D) -> void:
	shootSound.play()
	raycast.enabled = true
	raycast.set_collide_with_bodies(true)
	raycast.force_raycast_update()
	
	
	if raycast.is_colliding():
	
		var hit_position: Vector3 = raycast.get_collision_point()
		create_flash_effect(hit_position)

		var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var shape: SphereShape3D = SphereShape3D.new()
		shape.radius = 3.0  # Radio de efecto

		var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(Basis(), hit_position)
		query.collision_mask = 1 << 0  # Capa 1 para cuerpos físicos
		query.collide_with_areas = false
		query.collide_with_bodies = true

		var results: Array[Dictionary] = space_state.intersect_shape(query, 64)

		for result: Dictionary in results:
			var body: Object = result["collider"]
			if body is CharacterBody3D and body.is_in_group("enemy"):
				var enemy: CharacterBody3D = body as CharacterBody3D
				var is_headshot: bool = false  # No hay precisión de cabeza en AOE
				enemy.receive_hit(damage, critMultiplier, is_headshot)
	raycast.enabled = false
	raycast.set_collide_with_bodies(false)
	emit_signal("shotFinished")


func create_flash_effect(explosionPosition: Vector3) -> void:
	var flash: MeshInstance3D = MeshInstance3D.new()
	get_tree().current_scene.add_child(flash)
	var radius: float = 3.0
	flash.mesh = SphereMesh.new()
	flash.scale = Vector3.ONE * radius
	flash.global_position = explosionPosition

	# Material autoiluminado amarillo
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.0, 0.02)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 1.0, 0.0, 0.02)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.material_override = mat

	

	# Tween para desvanecer y eliminar
	var explosionTween: Tween = create_tween()
	explosionTween.tween_property(flash, "scale", Vector3.ONE * (radius * 1.5), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	explosionTween.tween_interval(0.05)
	explosionTween.tween_property(mat, "emission", Color(1, 1, 0, 0), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	explosionTween.tween_callback(flash.queue_free)


extends CharacterBody3D

signal weapon_changed(weapon_name: String, ammo: int)
signal ammo_updated(weapon_name: String, ammo: int)
signal update_ult_charge(charge: int)
signal healthChanged(currentHealth: int, hurt: bool)

var speed: float = WALK_SPEED
var jump_count: int = 0
var wall_momentum_stopped: bool = false
var max_jump_count: int = 1
var on_ladder: bool = false
var can_grab_ladder: bool = true
var gamePaused: bool = false

var health: int = 100
var isAlive: bool = true

var was_on_floor: bool = true
var landing_sound_enabled: bool = false
var finished_loading: bool = false
const WALK_SPEED: float = 8.0
const JUMP_VELOCITY: float = 6.5
const SENSITIVITY: float = 0.005

const DASH_FORCE: float = 45.0
const DASH_DURATION: float = 0.2
const DASH_COOLDOWN: float = 1.0

var preserve_dash_momentum: bool = false
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO


# bob variables
const BOB_FREQUENCY: float = 3.0
const BOB_AMPLITUDE: float = 0.05
var t_bob: float = 0.0

# fov variables
const BASE_FOV: float = 80.0
const FOV_CHANGE: float = 1.3

## Controller constants
const JOYSTICK_SENSITIVITY: float = 5.0
const DEADZONE: float = 0.3

# Custom gravity setting to make it feel a bit more snappier.
var gravity: int = 11

enum WeaponState {
	ULTIMATE,
	WEAPON_PISTOL,
	WEAPON_RIFLE,
	WEAPON_SPECIAL,
	WEAPON_HEAVY
}

var current_weapon_state : WeaponState
var currentWeapon: Node3D
var pistolAmmo: int = 0
var rifleAmmo: int = 0
var specialAmmo: int = 0
var heavyAmmo: int = 0
var ultimateAmmo: int
var shotFinished: bool = true

var shake_strength: float = 0.0
var shake_decay: float = 10.0
var shake_frequency: float = 20.0
var shake_timer: float = 0.0
var is_shaking: bool = false

var ultimateCharge: int
var has_used_ultimate: bool = false

@onready var playerHead: Node3D = $playerHead
@onready var camera: Camera3D = $playerHead/Camera3D
@onready var base_transform: Transform3D = camera.transform
@onready var pistola: Node3D = $playerHead/Camera3D/Pistol
@onready var JudgeRevolver: Node3D = $playerHead/Camera3D/JudgeRevolverRoot
@onready var rifle: Node3D = $playerHead/Camera3D/RifleNode
@onready var DBShotgun: Node3D = $playerHead/Camera3D/DBShotgun
@onready var GlassCannon: Node3D = $playerHead/Camera3D/GlassCannon
@onready var hitscan_RayCast: RayCast3D = $playerHead/Camera3D/hitscanRayCast
@onready var hitscan_RayCast_endpoint: Node3D = $playerHead/Camera3D/raycastEnd
@onready var ultimateChargeTimer: Timer = $ultimateChargeTimer
@onready var pauseMenu: Control = $HUD/PauseMenu


func _ready() -> void:
	for child: Node in camera.get_children():
		# Solo conectar si el nodo tiene las señales
		if child.has_signal("criticalHit") and child.has_signal("shotFinished"):
			child.connect("criticalHit", Callable(self, "_headshot"))
			child.connect("shotFinished", Callable(self, "_can_shoot"))
	ultimateCharge = 0
	hitscan_RayCast.set_enabled(false)
	hitscan_RayCast.collide_with_areas = true
	isAlive = true
	JudgeRevolver.shotFinished.connect(Callable(self,"disableShake"))
	current_weapon_state = WeaponState.WEAPON_PISTOL
	currentWeapon = pistola
	pistolAmmo = pistola.maxAmmo
	rifleAmmo = rifle.maxAmmo
	specialAmmo = DBShotgun.maxAmmo
	heavyAmmo = GlassCannon.maxAmmo
	ultimateAmmo = 0
	$HUD/PlayerHUD.updateAmmoCounts()
	set_process(false)
	await get_tree().process_frame  # o await get_tree().physics_frame
	set_process(true)
	await get_tree().create_timer(0.1).timeout
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	landing_sound_enabled = true
	finished_loading = true
	pauseMenu.connect("gameUnpaused", Callable(self, "_unpauseGame"))
	

func _unpauseGame() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pauseMenu.visible = false
	get_tree().paused = false

func _unhandled_input(event: InputEvent)-> void:
	if !finished_loading:
		return

	if event is InputEventMouseMotion and isAlive:
		playerHead.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
	if Input.is_action_just_pressed("pause"):
		if !gamePaused:
			pauseMenu.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
		else:
			_unpauseGame()
	
	# Lógica de cambio de armas
	if isAlive:
		if Input.is_action_just_pressed("swapWeapon1"):
			if current_weapon_state != WeaponState.WEAPON_PISTOL:
				await changeWeapons(pistola, WeaponState.WEAPON_PISTOL)
				emit_signal("weapon_changed", "Pistol", pistolAmmo)
		elif Input.is_action_just_pressed("swapWeapon2"):
			if current_weapon_state != WeaponState.WEAPON_RIFLE:
				await changeWeapons(rifle, WeaponState.WEAPON_RIFLE)
				emit_signal("weapon_changed", "Rifle", rifleAmmo)
		elif Input.is_action_just_pressed("swapWeapon3"):
			if current_weapon_state != WeaponState.WEAPON_SPECIAL:
				await changeWeapons(DBShotgun, WeaponState.WEAPON_SPECIAL)
				DBShotgun.checkForReload()
				emit_signal("weapon_changed", "DBShotgun", specialAmmo)
		elif Input.is_action_just_pressed("swapWeapon4"):
			if current_weapon_state != WeaponState.WEAPON_HEAVY:
				await changeWeapons(GlassCannon, WeaponState.WEAPON_HEAVY)
				emit_signal("weapon_changed", "GlassCannon", heavyAmmo)
		elif Input.is_action_just_pressed("useUltimate"):
			if current_weapon_state != WeaponState.ULTIMATE and ultimateCharge == 100:
				has_used_ultimate = true
				await changeWeapons(JudgeRevolver, WeaponState.ULTIMATE)
				emit_signal("weapon_changed", "Ultimate", ultimateAmmo)
		
		# Handle jump.
		if Input.is_action_just_pressed("jump") and isAlive:
			if is_on_floor() or jump_count < max_jump_count or is_dashing:
				velocity.y = JUMP_VELOCITY
				if is_on_floor():
					$JumpSFX.play()
				if !is_on_floor() and jump_count < max_jump_count and !on_ladder:
					$DoubleJump.play()
				
				if is_dashing:
					is_dashing = false
					preserve_dash_momentum = true
				
			jump_count += 1
	
	

func _process(delta: float) -> void:
	if !finished_loading or !isAlive:
		return
	
	var look_x: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var look_y: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)

	var stick_input: Vector2 = Vector2(look_x, look_y)

	# Aplicar zona muerta
	if stick_input.length() > DEADZONE:
		playerHead.rotate_y(-stick_input.x * JOYSTICK_SENSITIVITY * delta)
		camera.rotate_x(-stick_input.y * JOYSTICK_SENSITIVITY * delta)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if shake_strength > 0.01:
		shake_timer += delta * shake_frequency
		var offset: Vector3 = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
		) * shake_strength
		# Aplica el shake a la posición local de la cámara
		camera.transform.origin = offset
		# Decae el shake
		shake_strength = lerp(shake_strength, 0.0, delta * shake_decay)
	else:
		# Resetea la posición cuando no hay shake
		camera.transform.origin = Vector3.ZERO


func _physics_process(delta: float) -> void:
	# TESTING
	#var speed_mps = velocity.length()
	#var speed_kmh = speed_mps * 3.6
	#print("Current speed: ", speed_kmh, " km/h")
	
	if !isAlive:
		return
	
	if is_on_floor() and not was_on_floor and landing_sound_enabled:
		$Jump_LandSound.play()
	
	
	was_on_floor = is_on_floor()
	
	# Add the gravity.
	if !is_on_floor() and !on_ladder:
		velocity.y -= gravity * delta
		if $WalkSound.playing:
			$WalkSound.stop()
	elif is_on_floor():
		jump_count = 0
	
	if on_ladder and isAlive:
		jump_count = 0
		if Input.is_action_pressed("moveForward"):
			velocity.y = speed * delta * 20
		elif Input.is_action_pressed("moveBackwards"):
			velocity.y = -speed * delta * 20
		else:
			velocity.y = 0
		
		# Jump from the ladder
		if Input.is_action_just_pressed("jump") and on_ladder:
			var jump_direction: Vector3 = global_transform.basis.z.normalized()
			velocity = jump_direction * 5
			velocity.y = JUMP_VELOCITY
			on_ladder = false
			can_grab_ladder = false
			get_tree().create_timer(0.5).timeout.connect(func() -> void: can_grab_ladder = true)
	
	# Lógica del disparo
	if Input.is_action_pressed("shoot") and isAlive and !currentWeapon.animationPlayer.is_playing():
		match current_weapon_state:
			WeaponState.WEAPON_PISTOL:
				if pistolAmmo > 0:
					currentWeapon.shoot(hitscan_RayCast)
					pistolAmmo -= 1
					emit_signal("ammo_updated", "Pistol", pistolAmmo)
			WeaponState.WEAPON_RIFLE:
				if rifleAmmo > 0:
					currentWeapon.shoot(hitscan_RayCast)
					rifleAmmo -= 1
					emit_signal("ammo_updated", "Rifle", rifleAmmo)
			WeaponState.WEAPON_SPECIAL:
				if specialAmmo > 0:
					currentWeapon.shoot(hitscan_RayCast)
					specialAmmo -= 2
					emit_signal("ammo_updated", "DBShotgun", specialAmmo)
			WeaponState.WEAPON_HEAVY:
				if heavyAmmo > 0:
					currentWeapon.shoot(hitscan_RayCast)
					heavyAmmo -= 1
					emit_signal("ammo_updated", "GlassCannon", heavyAmmo)
			WeaponState.ULTIMATE:
				if ultimateAmmo > 0:
					currentWeapon.shoot(hitscan_RayCast)
					ultimateAmmo -= 1
					emit_signal("ammo_updated", "Ultimate", ultimateAmmo)
					if !is_shaking:
						trigger_camera_shake(0.5)
						is_shaking = true

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir: Vector2 = Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBackwards")
	if not preserve_dash_momentum:
		if isAlive:
			var direction: Vector3 = (playerHead.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			if is_on_floor():
				if direction:
					velocity.x = direction.x * speed
					velocity.z = direction.z * speed
					if not $WalkSound.playing:
						$WalkSound.play()
				else:
					velocity.x = lerp(velocity.x, direction.x * speed, delta * 10.0)
					velocity.z = lerp(velocity.z, direction.z * speed, delta * 10.0)
					if $WalkSound.playing:
						$WalkSound.stop()
			else:
				if direction:
					velocity.x = lerp(velocity.x, direction.x * speed, delta * 5.0)
					velocity.z = lerp(velocity.z, direction.z * speed, delta * 5.0)
				else:
					velocity.x = lerp(velocity.x, direction.x * speed, delta * 1.0)
					velocity.z = lerp(velocity.z, direction.z * speed, delta * 1.0)
				if $WalkSound.playing:
					$WalkSound.stop()
			
			if Input.is_action_just_pressed("dash") and !is_dashing and dash_cooldown_timer <= 0.0:
				$DashSFX.play()
				if direction != Vector3.ZERO:
					dash_direction = direction.normalized()
				else:
					# Si no hay input de movimiento, dash hacia adelante
					dash_direction = -playerHead.transform.basis.z.normalized()

				is_dashing = true
				dash_timer = DASH_DURATION
				dash_cooldown_timer = DASH_COOLDOWN
		
			
			# Head bob
			t_bob += delta * velocity.length() * float(is_on_floor())
			camera.transform.origin = _headbob(t_bob)
			
			if is_dashing:
				velocity = dash_direction * DASH_FORCE
				dash_timer -= delta
				if dash_timer <= 0.0:
					is_dashing = false
					velocity = velocity.lerp(Vector3.ZERO, 0.7)
			else:
				dash_cooldown_timer -= delta
			
			
			# FOV 
			var velocity_clamped: float = clamp(velocity.length(), 0.5, WALK_SPEED * 2)
			var fov_multiplier: float
			if is_dashing:
				fov_multiplier = 1.5
			else:
				fov_multiplier = 1.0  # durante dash, reduce el cambio
			var target_fov: float = BASE_FOV + FOV_CHANGE * velocity_clamped * fov_multiplier
			camera.fov = lerp(camera.fov, target_fov, delta * 6.0)
	else:
		preserve_dash_momentum = false
	
	move_and_slide()


func _headbob(time: float) -> Vector3:
	var pos: Vector3 = Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLITUDE
	pos.x = cos(time * BOB_FREQUENCY/2) * BOB_AMPLITUDE/2
	return pos

func trigger_camera_shake(strength: float) -> void:
	shake_strength = strength
	shake_timer = 0.0

func disableShake() -> void:
	is_shaking = false

func playerDeath() -> void:
	health = 0
	$DeathSFX.play()
	isAlive = false
	velocity = Vector3(0,0,0)


func _on_ladder_area_body_entered(body: Object) -> void:
	if body.is_in_group("player"):
		on_ladder = true


func _on_ladder_area_body_exited(body: Object) -> void:
	if body.is_in_group("player"):
		on_ladder = false
		can_grab_ladder = true

func _can_shoot() -> void:
	shotFinished = true

func changeWeapons(newWeapon: Node3D, newState: WeaponState) -> void:
	currentWeapon.animationPlayer.play("changeGun")
	await get_tree().create_timer(0.3).timeout
	currentWeapon.visible = false
	if has_used_ultimate and current_weapon_state == WeaponState.ULTIMATE and newState != WeaponState.ULTIMATE:
		ultimateAmmo = 0
		ultimateCharge = 0
		has_used_ultimate = false
		emit_signal("update_ult_charge", ultimateCharge)
		ultimateChargeTimer.start()
	current_weapon_state = newState
	currentWeapon = newWeapon
	currentWeapon.visible = true
	currentWeapon.animationPlayer.play_backwards("changeGun")

func _headshot(superCharge: int) -> void:
	if health < 100:
		health += 5
	elif health > 95:
		health = 100
	emit_signal("healthChanged", health, false)
	if ultimateCharge < 100:
		ultimateCharge += superCharge
		if ultimateCharge >= 100:
			ultimateCharged()
		emit_signal("update_ult_charge", ultimateCharge)

func _on_ultimate_charge_timer_timeout() -> void:
	if ultimateCharge < 100:
		ultimateCharge += 1
		if ultimateCharge >= 100:
			ultimateCharged()
		emit_signal("update_ult_charge", ultimateCharge)

func ultimateCharged() -> void:
	$UltReadySFX.play()
	ultimateCharge = 100
	ultimateAmmo = 6
	ultimateChargeTimer.stop()

func recieve_hit(damage: int) -> void:
	if isAlive:
		health -= damage
		emit_signal("healthChanged", health, true)
		if health <= 0:
			playerDeath()
		else:
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			var randomPitch: float = rng.randf_range(0.9, 1.1)
			$HurtSFX.set_pitch_scale(randomPitch)
			$HurtSFX.play()

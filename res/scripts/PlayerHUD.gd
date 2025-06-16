extends Control

const PISTOLAMMO_COLOR: Color = Color(1, 1, 0)
const RIFLEAMMO_COLOR: Color = Color(0, 1, 0)
const SPECIALAMMO_COLOR: Color = Color(0, 0, 1)
const HEAVYAMMO_COLOR: Color = Color(0.5, 0, 0.5)
const ULTIMATEAMMO_COLOR: Color = Color(1, 0, 0)

var pistolAmmo: int 
var rifleAmmo: int = 0
var specialAmmo: int = 0
var heavyAmmo: int = 0
var ultimateAmmo: int
var playerHealth: int
var playerIsAlive: bool = true

@onready var player: CharacterBody3D = get_tree().get_root().get_node("World/Player")
@onready var ammoLabel: Label = $VBoxContainer/Bottom/HBoxContainer/MiddleSpace/VBoxContainer/HBoxContainer/PanelContainer3/AmmoLabel
@onready var ultLabel: Label = $VBoxContainer/Bottom/HBoxContainer/MiddleSpace/VBoxContainer/HBoxContainer/PanelContainer2/UltimateLabel
@onready var healthLabel: Label = $VBoxContainer/Bottom/HBoxContainer/MiddleSpace/VBoxContainer/HBoxContainer/PanelContainer/HealthLabel
@onready var remainingAmmoPistol: Label = $VBoxContainer/Bottom/HBoxContainer/RightSpace/VBoxContainer/Bottom/HBoxContainer/Center/HBoxContainer/Ammo1/AmmoLabel1
@onready var remainingAmmoRifle: Label = $VBoxContainer/Bottom/HBoxContainer/RightSpace/VBoxContainer/Bottom/HBoxContainer/Center/HBoxContainer/Ammo2/AmmoLabel2
@onready var remainingAmmoSpecial: Label = $VBoxContainer/Bottom/HBoxContainer/RightSpace/VBoxContainer/Bottom/HBoxContainer/Center/HBoxContainer/Ammo3/AmmoLabel3
@onready var remainingAmmoHeavy: Label = $VBoxContainer/Bottom/HBoxContainer/RightSpace/VBoxContainer/Bottom/HBoxContainer/Center/HBoxContainer/Ammo4/AmmoLabel4
@onready var scoreLabel: Label = $VBoxContainer/Top/MarginContainer/VBoxContainer/CurrentBonusAmmount/CurrentBonusLabel

@onready var playerHitRect: ColorRect = $playerHitRect

@onready var stateLabel: Label = $Label

func _ready() -> void:
	## Coloreado de distintos labels
	remainingAmmoPistol.add_theme_color_override("font_color", PISTOLAMMO_COLOR)
	remainingAmmoRifle.add_theme_color_override("font_color", RIFLEAMMO_COLOR)
	remainingAmmoSpecial.add_theme_color_override("font_color", SPECIALAMMO_COLOR)
	remainingAmmoHeavy.add_theme_color_override("font_color", HEAVYAMMO_COLOR)
	ammoLabel.add_theme_color_override("font_color", PISTOLAMMO_COLOR)
	
	## Conectar señales
	player.connect("weapon_changed", Callable(self, "_on_weapon_changed"))
	player.connect("ammo_updated", Callable(self, "_on_ammo_updated"))
	player.connect("update_ult_charge", Callable(self, "_on_ultimate_charge_updated"))
	player.connect("healthChanged", Callable(self, "_on_health_updated"))
	#player.connect("playerStateChanged", Callable(self, "_stateMachine"))
	CombatManager.connect("updateScore", Callable(self, "_update_score"))
	CombatManager.updateScoreForUI()
	playerHitRect.visible = false
	playerIsAlive = true


func _on_weapon_changed(weapon_name: String, ammo: int) -> void:
	ammoLabel.set_text(str(ammo))
	match weapon_name:
		"Pistol":
			ammoLabel.add_theme_color_override("font_color", PISTOLAMMO_COLOR)
		"Rifle":
			ammoLabel.add_theme_color_override("font_color", RIFLEAMMO_COLOR)
		"DBShotgun":
			ammoLabel.add_theme_color_override("font_color", SPECIALAMMO_COLOR)
		"GlassCannon":
			ammoLabel.add_theme_color_override("font_color", HEAVYAMMO_COLOR)
		"Ultimate":
			ammoLabel.add_theme_color_override("font_color", ULTIMATEAMMO_COLOR)

func _on_ammo_updated(weapon_name: String, ammo: int) -> void:
	ammoLabel.set_text(str(ammo))
	match weapon_name:
		"Pistol":
			remainingAmmoPistol.set_text(str(ammo))
		"Rifle":
			remainingAmmoRifle.set_text(str(ammo))
		"DBShotgun":
			remainingAmmoSpecial.set_text(str(ammo))
		"GlassCannon":
			remainingAmmoHeavy.set_text(str(ammo))
		"Ultimate":
			pass

func updateAmmoCounts() -> void:
	pistolAmmo = player.pistolAmmo
	rifleAmmo = player.rifleAmmo
	specialAmmo = player.specialAmmo
	heavyAmmo = player.heavyAmmo
	remainingAmmoPistol.set_text(str(pistolAmmo))
	remainingAmmoRifle.set_text(str(rifleAmmo))
	remainingAmmoSpecial.set_text(str(specialAmmo))
	remainingAmmoHeavy.set_text(str(heavyAmmo))

func _on_ultimate_charge_updated(charge: int) -> void:
	ultLabel.text = str(charge) + "%"
	if charge == 100:
		ultLabel.add_theme_color_override("font_color", Color(1.0,0.5,0.0,1.0))
	else:
		ultLabel.add_theme_color_override("font_color", Color(1.0,1.0,1.0,0.25))

func _on_health_updated(health: int, damaged: bool) -> void:
	healthLabel.set_text(str(health))
	if damaged:
		playerHitRect.visible = true
		await get_tree().create_timer(0.1).timeout
		if playerIsAlive:
			playerHitRect.visible = false

func playerDeath() -> void:
	playerIsAlive = false
	playerHitRect.visible = true

func _update_score(score: int) -> void:
	scoreLabel.text = str(score) + "$"

func _stateMachine(playerState: int) -> void:
	match playerState:
		player.StateMachine.GROUNDED:
			stateLabel.set_text("Suelo")
		player.StateMachine.AIRBORNE:
			stateLabel.set_text("Saltando")

extends Control

signal closeCredits

@onready var text: RichTextLabel = $MarginContainer/ScrollContainer/creditText
@onready var scrollContainer: ScrollContainer = $MarginContainer/ScrollContainer

func _unhandled_input(_event: InputEvent) -> void:
	if (Input.is_action_pressed("pause") || Input.is_action_just_pressed("menuBack")):
		emit_signal("closeCredits")

func _process(_delta: float) -> void:
	if Input.is_action_pressed("menuUp"):
		scrollContainer.scroll_vertical -= 5
	if Input.is_action_pressed("menuDown"):
		scrollContainer.scroll_vertical += 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var file: FileAccess = FileAccess.open("res://res/textFiles/credits.txt", FileAccess.READ)
	text.text = file.get_as_text()


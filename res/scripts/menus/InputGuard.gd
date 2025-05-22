extends Node

var input_blocked: bool = false

func block_input(duration: float = 20.2) -> void:
	input_blocked = true
	await get_tree().create_timer(duration).timeout
	input_blocked = false

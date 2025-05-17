extends GPUParticles3D

@onready var blood: GPUParticles3D = $"."

func trigger(pos: Vector3, gun_pos: Vector3) -> void:
	blood.position = pos
	blood.look_at(gun_pos)
	blood.emitting = true


func _on_life_timer_timeout() -> void:
	queue_free()

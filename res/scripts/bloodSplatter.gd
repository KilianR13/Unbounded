extends GPUParticles3D

@onready var blood = $"."

func trigger(pos, gun_pos):
	blood.position = pos
	blood.look_at(gun_pos)
	blood.emitting = true


func _on_life_timer_timeout():
	queue_free()

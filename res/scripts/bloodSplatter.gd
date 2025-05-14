extends GPUParticles3D

@onready var blood = $"."
var ammount = 8

func trigger(pos, gun_pos, headshot: bool):
	if headshot:
		ammount *= 2
	blood.position = pos
	blood.look_at(gun_pos)
	blood.emitting = true

extends Camera3D

@export var period: float = 0.1
@export var magnitude: float = 0.1

func _camera_shake() -> void:
	var initial_transform: Transform3D = self.transform 
	var elapsed_time: float = 0.0

	while elapsed_time < period:
		var offset: Vector3 = Vector3(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude),
			0.0
		)

		self.transform.origin = initial_transform.origin + offset
		elapsed_time += get_process_delta_time()
		await get_tree().process_frame

	self.transform = initial_transform

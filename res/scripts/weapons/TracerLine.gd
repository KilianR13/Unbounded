extends MeshInstance3D
class_name TracerLine

@export var from: Vector3 = Vector3.ZERO
@export var to: Vector3 = Vector3.ZERO
@export var color: Color = Color(1, 0.7, 0.3)
@export var line_width: float = 0.05

var timer: float = 0.0
@export var fade_time: float = 0.5

func _ready() -> void:
	var imesh: ImmediateMesh = ImmediateMesh.new()
	imesh.surface_begin(Mesh.PRIMITIVE_LINES)
	imesh.set_color(color)
	imesh.add_vertex(from)
	imesh.add_vertex(to)
	imesh.surface_end()
	mesh = imesh

func _process(delta: float) -> void:
	timer += delta
	var alpha: float = clamp(1.0 - timer / fade_time, 0, 1)

	if material_override:
		var col: Color = material_override.albedo_color
		col.a = alpha
		material_override.albedo_color = col
	else:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(color.r, color.g, color.b, alpha)
		mat.flags_transparent = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material_override = mat

	if alpha <= 0.0:
		queue_free()

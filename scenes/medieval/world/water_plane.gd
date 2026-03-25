extends Node3D
## Lough Key water surface - animated lake with reflections and waves.

const WATER_LEVEL := 0.0
const LAKE_SIZE := 150.0

var water_mesh: MeshInstance3D
var water_material: ShaderMaterial

func _ready() -> void:
	_create_water_surface()
	_create_underwater_volume()

func _create_water_surface() -> void:
	water_mesh = MeshInstance3D.new()
	water_mesh.name = "WaterSurface"

	var plane := PlaneMesh.new()
	plane.size = Vector2(LAKE_SIZE, LAKE_SIZE)
	plane.subdivide_width = 64
	plane.subdivide_depth = 64
	water_mesh.mesh = plane

	# Position at lake center
	water_mesh.position = Vector3(100.0, WATER_LEVEL, 100.0)

	# Water shader material
	water_material = ShaderMaterial.new()
	water_material.shader = preload("res://shaders/medieval/lake_water.gdshader")
	water_material.set_shader_parameter("deep_color", Color(0.05, 0.15, 0.12, 0.85))
	water_material.set_shader_parameter("shallow_color", Color(0.1, 0.3, 0.2, 0.6))
	water_material.set_shader_parameter("wave_speed", 0.02)
	water_material.set_shader_parameter("wave_strength", 0.15)
	water_material.set_shader_parameter("foam_threshold", 0.8)

	water_mesh.material_override = water_material
	water_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_child(water_mesh)

func _create_underwater_volume() -> void:
	# Dark volume below water for depth effect
	var underwater := MeshInstance3D.new()
	underwater.name = "UnderwaterVolume"

	var box := BoxMesh.new()
	box.size = Vector3(LAKE_SIZE, 8.0, LAKE_SIZE)
	underwater.mesh = box
	underwater.position = Vector3(100.0, WATER_LEVEL - 4.5, 100.0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.02, 0.06, 0.05)
	mat.roughness = 1.0
	underwater.material_override = mat
	underwater.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_child(underwater)

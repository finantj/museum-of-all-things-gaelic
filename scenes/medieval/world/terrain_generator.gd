extends Node3D
## Procedural terrain generator for the Lough Key / Moylurg region.
## Creates a heightmap-based terrain with the lake basin, rolling drumlins,
## and the distinctive islands of Lough Key.

const TERRAIN_SIZE := 256 # World units per side
const TERRAIN_RESOLUTION := 128 # Vertices per side
const MAX_HEIGHT := 25.0
const LAKE_LEVEL := 0.0
const LAKE_CENTER := Vector2(100.0, 100.0) # Approx center of Lough Key
const LAKE_RADIUS := 45.0 # Main lake body radius

# Island positions (relative to terrain) - historically accurate layout
const CASTLE_ISLAND_POS := Vector2(95.0, 105.0) # The Rock - MacDermot stronghold
const TRINITY_ISLAND_POS := Vector2(88.0, 92.0) # Monastery island
const DRUMMAN_ISLAND_POS := Vector2(105.0, 95.0) # Smaller island

var terrain_mesh: MeshInstance3D
var collision_body: StaticBody3D
var collision_shape: CollisionShape3D
var material: ShaderMaterial
var height_data: PackedFloat32Array
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 1250
	_generate_heightmap()
	_build_terrain_mesh()
	_add_collision()
	_add_ground_details()

func _generate_heightmap() -> void:
	height_data = PackedFloat32Array()
	height_data.resize(TERRAIN_RESOLUTION * TERRAIN_RESOLUTION)

	for z in range(TERRAIN_RESOLUTION):
		for x in range(TERRAIN_RESOLUTION):
			var world_x := float(x) / TERRAIN_RESOLUTION * TERRAIN_SIZE
			var world_z := float(z) / TERRAIN_RESOLUTION * TERRAIN_SIZE
			var pos := Vector2(world_x, world_z)

			var height := _sample_height(pos)
			height_data[z * TERRAIN_RESOLUTION + x] = height

func _sample_height(pos: Vector2) -> float:
	var height := 0.0

	# Base rolling hills (drumlins typical of Roscommon)
	height += _fbm_noise(pos * 0.008, 4) * MAX_HEIGHT * 0.6
	height += _fbm_noise(pos * 0.02, 3) * MAX_HEIGHT * 0.25
	height += _fbm_noise(pos * 0.05, 2) * MAX_HEIGHT * 0.1

	# Carve out the lake basin
	var lake_dist := pos.distance_to(LAKE_CENTER)
	var lake_factor := smoothstep(LAKE_RADIUS * 0.6, LAKE_RADIUS * 1.2, lake_dist)

	# Lake has irregular shape - add noise to shoreline
	var shore_noise := _fbm_noise(pos * 0.03 + Vector2(500, 500), 3) * 15.0
	lake_factor = smoothstep(LAKE_RADIUS * 0.5 + shore_noise, LAKE_RADIUS * 1.1 + shore_noise, lake_dist)

	# Lake depth
	var lake_depth := -4.0 * (1.0 - lake_factor)
	height = lerp(lake_depth, height, lake_factor)

	# Raise islands within the lake
	height = _add_island(pos, CASTLE_ISLAND_POS, 8.0, 3.5, height)
	height = _add_island(pos, TRINITY_ISLAND_POS, 10.0, 2.5, height)
	height = _add_island(pos, DRUMMAN_ISLAND_POS, 6.0, 2.0, height)

	# Shore areas - gentle slopes down to water
	var shore_blend := smoothstep(LAKE_RADIUS * 1.0, LAKE_RADIUS * 1.4, lake_dist)
	height = lerp(height, max(height, 0.5), shore_blend * 0.3)

	return height

func _add_island(pos: Vector2, island_center: Vector2, island_radius: float, island_height: float, current_height: float) -> float:
	var dist := pos.distance_to(island_center)
	if dist < island_radius:
		var t := 1.0 - (dist / island_radius)
		t = t * t * (3.0 - 2.0 * t) # Smoothstep
		var island_h := island_height * t
		# Add small terrain variation on islands
		island_h += _fbm_noise(pos * 0.1 + Vector2(200, 200), 2) * 0.5 * t
		return max(current_height, island_h)
	return current_height

func _fbm_noise(pos: Vector2, octaves: int) -> float:
	var value := 0.0
	var amplitude := 1.0
	var frequency := 1.0
	var max_val := 0.0

	for i in range(octaves):
		value += _simple_noise(pos * frequency) * amplitude
		max_val += amplitude
		amplitude *= 0.5
		frequency *= 2.0

	return value / max_val

func _simple_noise(pos: Vector2) -> float:
	# Hash-based noise function
	var ix := int(floor(pos.x))
	var iz := int(floor(pos.y))
	var fx := pos.x - floor(pos.x)
	var fz := pos.y - floor(pos.y)

	# Smoothstep
	fx = fx * fx * (3.0 - 2.0 * fx)
	fz = fz * fz * (3.0 - 2.0 * fz)

	var a := _hash2d(ix, iz)
	var b := _hash2d(ix + 1, iz)
	var c := _hash2d(ix, iz + 1)
	var d := _hash2d(ix + 1, iz + 1)

	return lerp(lerp(a, b, fx), lerp(c, d, fx), fz)

func _hash2d(x: int, z: int) -> float:
	var n := x * 374761393 + z * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	return float(n & 0x7fffffff) / float(0x7fffffff)

func _build_terrain_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var step := float(TERRAIN_SIZE) / float(TERRAIN_RESOLUTION - 1)

	# Generate vertices
	for z in range(TERRAIN_RESOLUTION):
		for x in range(TERRAIN_RESOLUTION):
			var height := height_data[z * TERRAIN_RESOLUTION + x]
			var pos := Vector3(x * step, height, z * step)

			# UV coordinates
			var uv := Vector2(float(x) / (TERRAIN_RESOLUTION - 1), float(z) / (TERRAIN_RESOLUTION - 1))

			# Color based on height for terrain splatting
			var color := _get_terrain_color(height, pos)

			st.set_uv(uv)
			st.set_color(color)
			st.add_vertex(pos)

	# Generate triangles
	for z in range(TERRAIN_RESOLUTION - 1):
		for x in range(TERRAIN_RESOLUTION - 1):
			var i := z * TERRAIN_RESOLUTION + x
			st.add_index(i)
			st.add_index(i + TERRAIN_RESOLUTION)
			st.add_index(i + 1)

			st.add_index(i + 1)
			st.add_index(i + TERRAIN_RESOLUTION)
			st.add_index(i + TERRAIN_RESOLUTION + 1)

	st.generate_normals()
	st.generate_tangents()

	var mesh := st.commit()
	terrain_mesh = MeshInstance3D.new()
	terrain_mesh.mesh = mesh
	terrain_mesh.name = "TerrainMesh"

	# Apply terrain material
	material = _create_terrain_material()
	terrain_mesh.material_override = material

	# Shadows
	terrain_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	add_child(terrain_mesh)

func _get_terrain_color(height: float, pos: Vector3) -> Color:
	if height < LAKE_LEVEL - 0.5:
		return Color(0.15, 0.12, 0.08) # Lake bed (dark mud)
	elif height < LAKE_LEVEL + 0.3:
		return Color(0.35, 0.3, 0.2) # Muddy shore
	elif height < LAKE_LEVEL + 1.5:
		return Color(0.25, 0.45, 0.15) # Lush grass near water
	elif height < MAX_HEIGHT * 0.4:
		return Color(0.2, 0.4, 0.12) # Forest green
	elif height < MAX_HEIGHT * 0.7:
		return Color(0.3, 0.35, 0.15) # Hillside
	else:
		return Color(0.35, 0.32, 0.25) # Rocky hilltop

func _create_terrain_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/medieval/terrain.gdshader")
	return mat

func _add_collision() -> void:
	collision_body = StaticBody3D.new()
	collision_body.name = "TerrainCollision"

	var shape := HeightMapShape3D.new()
	shape.map_width = TERRAIN_RESOLUTION
	shape.map_depth = TERRAIN_RESOLUTION
	shape.map_data = height_data

	collision_shape = CollisionShape3D.new()
	collision_shape.shape = shape

	# Scale collision to match mesh
	var scale_factor := float(TERRAIN_SIZE) / float(TERRAIN_RESOLUTION - 1)
	collision_body.scale = Vector3(scale_factor, 1.0, scale_factor)

	collision_body.add_child(collision_shape)
	add_child(collision_body)

func _add_ground_details() -> void:
	# Scatter rocks on hillsides
	for i in range(200):
		var pos := Vector2(rng.randf() * TERRAIN_SIZE, rng.randf() * TERRAIN_SIZE)
		var height := _sample_height(pos)
		if height > 3.0 and height < MAX_HEIGHT * 0.8:
			_place_rock(Vector3(pos.x, height, pos.y))

func _place_rock(pos: Vector3) -> void:
	var rock := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = rng.randf_range(0.15, 0.6)
	mesh.height = mesh.radius * rng.randf_range(1.0, 1.6)
	rock.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.38, 0.35)
	mat.roughness = 0.9
	rock.material_override = mat

	rock.position = pos
	rock.rotation.y = rng.randf() * TAU
	rock.rotation.x = rng.randf_range(-0.2, 0.2)

	add_child(rock)

## Get height at a world position (for other systems to query)
func get_height_at(world_pos: Vector3) -> float:
	return _sample_height(Vector2(world_pos.x, world_pos.z))

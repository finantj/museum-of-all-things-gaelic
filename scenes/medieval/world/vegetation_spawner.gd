extends Node3D
## Spawns trees, bushes, and grass across the terrain.
## Flora appropriate to 13th century Connacht - oak, ash, hazel, birch, holly.

const TREE_COUNT := 400
const BUSH_COUNT := 300
const TERRAIN_SIZE := 256.0
const LAKE_CENTER := Vector2(100.0, 100.0)
const LAKE_RADIUS := 45.0

var rng := RandomNumberGenerator.new()
var trees: Array[Node3D] = []

# Tree species of medieval Roscommon
enum TreeType { OAK, ASH, HAZEL, BIRCH, HOLLY, WILLOW, ALDER }

func _ready() -> void:
	rng.seed = 1250
	call_deferred("_spawn_all")

func _spawn_all() -> void:
	_spawn_trees()
	_spawn_bushes()
	_spawn_reeds()

func _spawn_trees() -> void:
	for i in range(TREE_COUNT):
		var pos := _random_land_position()
		if pos == Vector3.ZERO:
			continue

		var tree_type: TreeType
		var height := pos.y

		# Tree distribution based on terrain
		if height < 1.0:
			tree_type = [TreeType.WILLOW, TreeType.ALDER].pick_random()
		elif height < 5.0:
			tree_type = [TreeType.OAK, TreeType.ASH, TreeType.HAZEL].pick_random()
		elif height < 12.0:
			tree_type = [TreeType.OAK, TreeType.BIRCH, TreeType.HOLLY].pick_random()
		else:
			tree_type = [TreeType.BIRCH, TreeType.HAZEL].pick_random()

		var tree := _create_tree(tree_type)
		tree.position = pos
		tree.rotation.y = rng.randf() * TAU
		var s := rng.randf_range(0.7, 1.3)
		tree.scale = Vector3(s, rng.randf_range(0.8, 1.2) * s, s)
		add_child(tree)
		trees.append(tree)

func _create_tree(type: TreeType) -> Node3D:
	var tree := Node3D.new()

	var trunk_height: float
	var trunk_radius: float
	var canopy_radius: float
	var canopy_height: float
	var trunk_color: Color
	var leaf_color: Color

	match type:
		TreeType.OAK:
			trunk_height = rng.randf_range(3.0, 5.0)
			trunk_radius = rng.randf_range(0.2, 0.4)
			canopy_radius = rng.randf_range(2.5, 4.0)
			canopy_height = rng.randf_range(3.0, 5.0)
			trunk_color = Color(0.3, 0.2, 0.1)
			leaf_color = Color(0.15, 0.35, 0.1)
			tree.name = "Oak"
		TreeType.ASH:
			trunk_height = rng.randf_range(4.0, 6.0)
			trunk_radius = rng.randf_range(0.15, 0.3)
			canopy_radius = rng.randf_range(2.0, 3.5)
			canopy_height = rng.randf_range(3.0, 4.5)
			trunk_color = Color(0.35, 0.3, 0.2)
			leaf_color = Color(0.2, 0.4, 0.15)
			tree.name = "Ash"
		TreeType.HAZEL:
			trunk_height = rng.randf_range(2.0, 3.5)
			trunk_radius = rng.randf_range(0.08, 0.15)
			canopy_radius = rng.randf_range(1.5, 2.5)
			canopy_height = rng.randf_range(2.0, 3.0)
			trunk_color = Color(0.35, 0.25, 0.15)
			leaf_color = Color(0.2, 0.38, 0.12)
			tree.name = "Hazel"
		TreeType.BIRCH:
			trunk_height = rng.randf_range(4.0, 7.0)
			trunk_radius = rng.randf_range(0.1, 0.18)
			canopy_radius = rng.randf_range(1.5, 2.5)
			canopy_height = rng.randf_range(2.5, 4.0)
			trunk_color = Color(0.8, 0.78, 0.7)
			leaf_color = Color(0.25, 0.45, 0.15)
			tree.name = "Birch"
		TreeType.HOLLY:
			trunk_height = rng.randf_range(2.0, 3.0)
			trunk_radius = rng.randf_range(0.08, 0.12)
			canopy_radius = rng.randf_range(1.0, 1.8)
			canopy_height = rng.randf_range(2.0, 3.0)
			trunk_color = Color(0.25, 0.2, 0.15)
			leaf_color = Color(0.08, 0.25, 0.08)
			tree.name = "Holly"
		TreeType.WILLOW:
			trunk_height = rng.randf_range(3.0, 4.5)
			trunk_radius = rng.randf_range(0.2, 0.35)
			canopy_radius = rng.randf_range(2.5, 4.0)
			canopy_height = rng.randf_range(3.0, 5.0)
			trunk_color = Color(0.3, 0.25, 0.15)
			leaf_color = Color(0.2, 0.4, 0.12)
			tree.name = "Willow"
		TreeType.ALDER:
			trunk_height = rng.randf_range(3.0, 5.0)
			trunk_radius = rng.randf_range(0.12, 0.22)
			canopy_radius = rng.randf_range(1.8, 3.0)
			canopy_height = rng.randf_range(2.5, 4.0)
			trunk_color = Color(0.28, 0.2, 0.12)
			leaf_color = Color(0.18, 0.35, 0.1)
			tree.name = "Alder"

	# Trunk
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = trunk_radius * 0.6
	trunk_mesh.bottom_radius = trunk_radius
	trunk_mesh.height = trunk_height
	trunk.mesh = trunk_mesh
	trunk.position.y = trunk_height / 2.0

	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = trunk_color
	trunk_mat.roughness = 0.95
	trunk.material_override = trunk_mat

	# Add collision to trunk
	var trunk_body := StaticBody3D.new()
	var trunk_col := CollisionShape3D.new()
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = trunk_radius
	trunk_shape.height = trunk_height
	trunk_col.shape = trunk_shape
	trunk_body.add_child(trunk_col)
	trunk.add_child(trunk_body)

	tree.add_child(trunk)

	# Canopy (multiple spheres for organic look)
	var num_canopy := rng.randi_range(2, 4)
	for j in range(num_canopy):
		var canopy := MeshInstance3D.new()
		var canopy_mesh := SphereMesh.new()
		var cr := canopy_radius * rng.randf_range(0.6, 1.0)
		canopy_mesh.radius = cr
		canopy_mesh.height = canopy_height * rng.randf_range(0.5, 1.0)
		canopy.mesh = canopy_mesh

		canopy.position = Vector3(
			rng.randf_range(-canopy_radius * 0.3, canopy_radius * 0.3),
			trunk_height + canopy_height * 0.3 + j * canopy_height * 0.15,
			rng.randf_range(-canopy_radius * 0.3, canopy_radius * 0.3)
		)

		var leaf_mat := StandardMaterial3D.new()
		leaf_mat.albedo_color = leaf_color.lerp(Color(0.3, 0.5, 0.15), rng.randf() * 0.3)
		leaf_mat.roughness = 0.85
		# Slight transparency for leaf edges
		leaf_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_HASH
		leaf_mat.albedo_color.a = 0.92
		canopy.material_override = leaf_mat
		canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

		tree.add_child(canopy)

	return tree

func _spawn_bushes() -> void:
	for i in range(BUSH_COUNT):
		var pos := _random_land_position()
		if pos == Vector3.ZERO or pos.y < 0.5:
			continue

		var bush := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = rng.randf_range(0.3, 0.8)
		mesh.height = rng.randf_range(0.4, 1.0)
		bush.mesh = mesh
		bush.position = pos
		bush.position.y += mesh.height * 0.3

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(
			rng.randf_range(0.1, 0.2),
			rng.randf_range(0.25, 0.4),
			rng.randf_range(0.08, 0.15)
		)
		mat.roughness = 0.9
		bush.material_override = mat

		add_child(bush)

func _spawn_reeds() -> void:
	# Reeds along the lakeshore
	for i in range(150):
		var angle := rng.randf() * TAU
		var dist := LAKE_RADIUS + rng.randf_range(-3.0, 5.0)
		var noise := rng.randf_range(-8.0, 8.0)
		var pos2d := LAKE_CENTER + Vector2(cos(angle), sin(angle)) * (dist + noise)

		# Check it's near water level
		var height := _get_approx_height(pos2d)
		if abs(height) > 1.5:
			continue

		var reed := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.01
		mesh.bottom_radius = 0.02
		mesh.height = rng.randf_range(0.8, 1.8)
		reed.mesh = mesh

		reed.position = Vector3(pos2d.x, height + mesh.height * 0.5, pos2d.y)
		reed.rotation.x = rng.randf_range(-0.1, 0.1)
		reed.rotation.z = rng.randf_range(-0.1, 0.1)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.4, 0.15)
		mat.roughness = 0.9
		reed.material_override = mat

		add_child(reed)

func _random_land_position() -> Vector3:
	for _attempt in range(10):
		var x := rng.randf() * TERRAIN_SIZE
		var z := rng.randf() * TERRAIN_SIZE
		var pos2d := Vector2(x, z)

		# Skip if in lake
		var lake_dist := pos2d.distance_to(LAKE_CENTER)
		if lake_dist < LAKE_RADIUS * 0.85:
			continue

		var height := _get_approx_height(pos2d)
		if height > 0.5:
			return Vector3(x, height, z)

	return Vector3.ZERO

func _get_approx_height(pos: Vector2) -> float:
	# Simplified height query - uses terrain generator if available
	var terrain = get_parent().get_node_or_null("TerrainGenerator")
	if terrain and terrain.has_method("get_height_at"):
		return terrain.get_height_at(Vector3(pos.x, 0, pos.y))

	# Fallback approximation
	var lake_dist := pos.distance_to(LAKE_CENTER)
	if lake_dist < LAKE_RADIUS:
		return -2.0
	return (lake_dist - LAKE_RADIUS) * 0.3

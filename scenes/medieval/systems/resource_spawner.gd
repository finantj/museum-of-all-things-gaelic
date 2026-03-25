extends Node3D
## Spawns harvestable resource nodes (trees, rocks, bushes) across the world.
## Resources respawn after a delay, Valheim-style.

signal resource_harvested(resource_type: String, amount: int, position: Vector3)

const TERRAIN_SIZE := 256.0
const LAKE_CENTER := Vector2(100.0, 100.0)
const LAKE_RADIUS := 45.0

var rng := RandomNumberGenerator.new()
var resource_nodes: Array[Dictionary] = []
var respawn_queue: Array[Dictionary] = []
const RESPAWN_TIME := 300.0 # 5 minutes

func _ready() -> void:
	rng.seed = 1251
	call_deferred("_spawn_resources")

func _process(delta: float) -> void:
	_process_respawns(delta)

func _spawn_resources() -> void:
	# Harvestable trees (separate from decorative vegetation)
	for i in range(120):
		var pos := _random_land_pos()
		if pos != Vector3.ZERO:
			_create_resource_node("tree", pos, {
				"health": 50.0,
				"drops": {"wood": 4},
				"tool_required": "axe"
			})

	# Stone deposits
	for i in range(60):
		var pos := _random_land_pos()
		if pos != Vector3.ZERO and pos.y > 2.0:
			_create_resource_node("stone_deposit", pos, {
				"health": 80.0,
				"drops": {"stone": 5},
				"tool_required": "pickaxe"
			})

	# Flint (near water)
	for i in range(40):
		var angle := rng.randf() * TAU
		var dist := LAKE_RADIUS + rng.randf_range(0.0, 8.0)
		var pos2d := LAKE_CENTER + Vector2(cos(angle), sin(angle)) * dist
		var height := _get_height(pos2d)
		if height > 0.0 and height < 2.0:
			_create_resource_node("flint_node", Vector3(pos2d.x, height, pos2d.y), {
				"health": 20.0,
				"drops": {"flint": 3},
				"tool_required": "none"
			})

	# Berry bushes
	for i in range(50):
		var pos := _random_land_pos()
		if pos != Vector3.ZERO and pos.y > 0.5 and pos.y < 8.0:
			_create_resource_node("berry_bush", pos, {
				"health": 10.0,
				"drops": {"berries": 3},
				"tool_required": "none"
			})

	# Mushrooms (in shaded forest areas)
	for i in range(40):
		var pos := _random_land_pos()
		if pos != Vector3.ZERO and pos.y > 1.0 and pos.y < 6.0:
			_create_resource_node("mushroom_cluster", pos, {
				"health": 5.0,
				"drops": {"mushroom": 2},
				"tool_required": "none"
			})

	# Clay deposits (near water)
	for i in range(20):
		var angle := rng.randf() * TAU
		var dist := LAKE_RADIUS + rng.randf_range(-2.0, 5.0)
		var pos2d := LAKE_CENTER + Vector2(cos(angle), sin(angle)) * dist
		var height := _get_height(pos2d)
		if height > -0.5 and height < 1.0:
			_create_resource_node("clay_deposit", Vector3(pos2d.x, max(0.0, height), pos2d.y), {
				"health": 40.0,
				"drops": {"clay": 5},
				"tool_required": "pickaxe"
			})

	# Iron ore (in hilly areas)
	for i in range(15):
		var pos := _random_land_pos()
		if pos != Vector3.ZERO and pos.y > 8.0:
			_create_resource_node("iron_deposit", pos, {
				"health": 120.0,
				"drops": {"iron": 3},
				"tool_required": "pickaxe"
			})

	# Resin trees
	for i in range(30):
		var pos := _random_land_pos()
		if pos != Vector3.ZERO and pos.y > 2.0:
			_create_resource_node("resin_tree", pos, {
				"health": 15.0,
				"drops": {"resin": 2, "wood": 1},
				"tool_required": "none"
			})

func _create_resource_node(type: String, pos: Vector3, data: Dictionary) -> void:
	var node := Node3D.new()
	node.name = "Resource_%s_%d" % [type, resource_nodes.size()]
	node.position = pos

	var mesh_inst := MeshInstance3D.new()
	var body := StaticBody3D.new()
	body.collision_layer = 4 # Pickable
	body.collision_mask = 0

	var col := CollisionShape3D.new()

	match type:
		"tree":
			# Trunk
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.15
			mesh.bottom_radius = 0.25
			mesh.height = 4.0
			mesh_inst.mesh = mesh
			mesh_inst.position.y = 2.0

			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.3, 0.2, 0.1)
			mat.roughness = 0.95
			mesh_inst.material_override = mat

			var shape := CylinderShape3D.new()
			shape.radius = 0.25
			shape.height = 4.0
			col.shape = shape
			col.position.y = 2.0

			# Simple canopy
			var canopy := MeshInstance3D.new()
			var canopy_mesh := SphereMesh.new()
			canopy_mesh.radius = 2.0
			canopy_mesh.height = 3.0
			canopy.mesh = canopy_mesh
			canopy.position.y = 5.0
			var leaf_mat := StandardMaterial3D.new()
			leaf_mat.albedo_color = Color(0.15, 0.35, 0.1)
			leaf_mat.roughness = 0.9
			canopy.material_override = leaf_mat
			node.add_child(canopy)

		"stone_deposit":
			var mesh := SphereMesh.new()
			mesh.radius = 0.8
			mesh.height = 1.0
			mesh_inst.mesh = mesh
			mesh_inst.position.y = 0.4

			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.45, 0.42, 0.4)
			mat.roughness = 0.9
			mesh_inst.material_override = mat

			var shape := SphereShape3D.new()
			shape.radius = 0.8
			col.shape = shape
			col.position.y = 0.4

		"flint_node":
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.3, 0.15, 0.25)
			mesh_inst.mesh = mesh
			mesh_inst.position.y = 0.08

			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.25, 0.25, 0.28)
			mat.roughness = 0.6
			mesh_inst.material_override = mat

			var shape := BoxShape3D.new()
			shape.size = Vector3(0.3, 0.15, 0.25)
			col.shape = shape
			col.position.y = 0.08

		"berry_bush":
			var mesh := SphereMesh.new()
			mesh.radius = 0.5
			mesh.height = 0.7
			mesh_inst.mesh = mesh
			mesh_inst.position.y = 0.35

			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.15, 0.3, 0.1)
			mat.roughness = 0.9
			mesh_inst.material_override = mat

			var shape := SphereShape3D.new()
			shape.radius = 0.5
			col.shape = shape
			col.position.y = 0.35

		"mushroom_cluster":
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.15
			mesh.bottom_radius = 0.05
			mesh.height = 0.2
			mesh_inst.mesh = mesh
			mesh_inst.position.y = 0.1

			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.6, 0.5, 0.3)
			mat.roughness = 0.85
			mesh_inst.material_override = mat

			var shape := CylinderShape3D.new()
			shape.radius = 0.2
			shape.height = 0.2
			col.shape = shape
			col.position.y = 0.1

		"clay_deposit":
			var mesh := SphereMesh.new()
			mesh.radius = 0.6
			mesh.height = 0.4
			mesh_inst.mesh = mesh
			mesh_inst.position.y = 0.15

			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.5, 0.35, 0.2)
			mat.roughness = 1.0
			mesh_inst.material_override = mat

			var shape := SphereShape3D.new()
			shape.radius = 0.6
			col.shape = shape
			col.position.y = 0.15

		"iron_deposit":
			var mesh := SphereMesh.new()
			mesh.radius = 0.7
			mesh.height = 0.9
			mesh_inst.mesh = mesh
			mesh_inst.position.y = 0.35

			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.35, 0.25, 0.2)
			mat.roughness = 0.7
			mat.metallic = 0.3
			mesh_inst.material_override = mat

			var shape := SphereShape3D.new()
			shape.radius = 0.7
			col.shape = shape
			col.position.y = 0.35

		"resin_tree":
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.12
			mesh.bottom_radius = 0.2
			mesh.height = 3.0
			mesh_inst.mesh = mesh
			mesh_inst.position.y = 1.5

			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.25, 0.18, 0.1)
			mat.roughness = 0.95
			mesh_inst.material_override = mat

			var shape := CylinderShape3D.new()
			shape.radius = 0.2
			shape.height = 3.0
			col.shape = shape
			col.position.y = 1.5

	# Store metadata for interaction
	body.set_meta("resource_type", type)
	body.set_meta("resource_data", data)
	body.set_meta("resource_health", data.health)
	body.set_meta("node_index", resource_nodes.size())

	body.add_child(col)
	node.add_child(mesh_inst)
	node.add_child(body)
	add_child(node)

	resource_nodes.append({
		"type": type,
		"position": pos,
		"data": data,
		"node": node,
		"active": true
	})

func harvest_resource(body: StaticBody3D, damage: float, tool_type: String) -> Dictionary:
	if not body.has_meta("resource_data"):
		return {}

	var data: Dictionary = body.get_meta("resource_data")
	var required_tool: String = data.get("tool_required", "none")

	# Check tool requirement
	if required_tool != "none" and tool_type != required_tool:
		return {"error": "Need a %s" % required_tool}

	# Apply damage
	var health: float = body.get_meta("resource_health")
	health -= damage
	body.set_meta("resource_health", health)

	if health <= 0:
		# Destroyed - give drops
		var idx: int = body.get_meta("node_index")
		var drops: Dictionary = data.drops.duplicate()
		_destroy_resource(idx)
		resource_harvested.emit(data.get("type", "unknown"), 1, body.global_position)
		return drops

	return {"partial": true, "remaining": health}

func _destroy_resource(index: int) -> void:
	if index >= resource_nodes.size():
		return

	resource_nodes[index].active = false
	resource_nodes[index].node.visible = false

	# Disable collision
	for child in resource_nodes[index].node.get_children():
		if child is StaticBody3D:
			child.collision_layer = 0

	# Queue respawn
	respawn_queue.append({
		"index": index,
		"timer": RESPAWN_TIME
	})

func _process_respawns(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(respawn_queue.size()):
		respawn_queue[i].timer -= delta
		if respawn_queue[i].timer <= 0:
			var idx: int = respawn_queue[i].index
			_respawn_resource(idx)
			to_remove.append(i)

	to_remove.reverse()
	for i in to_remove:
		respawn_queue.remove_at(i)

func _respawn_resource(index: int) -> void:
	if index >= resource_nodes.size():
		return

	resource_nodes[index].active = true
	resource_nodes[index].node.visible = true

	# Re-enable collision
	for child in resource_nodes[index].node.get_children():
		if child is StaticBody3D:
			child.collision_layer = 4
			child.set_meta("resource_health", resource_nodes[index].data.health)

func _random_land_pos() -> Vector3:
	for _attempt in range(10):
		var x := rng.randf() * TERRAIN_SIZE
		var z := rng.randf() * TERRAIN_SIZE
		var pos2d := Vector2(x, z)

		if pos2d.distance_to(LAKE_CENTER) < LAKE_RADIUS * 0.9:
			continue

		var height := _get_height(pos2d)
		if height > 0.5:
			return Vector3(x, height, z)

	return Vector3.ZERO

func _get_height(pos: Vector2) -> float:
	var terrain = get_parent().get_node_or_null("TerrainGenerator")
	if terrain and terrain.has_method("get_height_at"):
		return terrain.get_height_at(Vector3(pos.x, 0, pos.y))

	var lake_dist := pos.distance_to(LAKE_CENTER)
	if lake_dist < LAKE_RADIUS:
		return -2.0
	return (lake_dist - LAKE_RADIUS) * 0.3

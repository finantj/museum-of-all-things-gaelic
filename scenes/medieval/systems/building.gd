extends Node
## Valheim-style building system.
## Place wattle walls, thatch roofs, wooden floors, doors, and stations.

signal piece_placed(piece_id: String, position: Vector3)
signal piece_removed(position: Vector3)
signal build_mode_changed(active: bool)

const SNAP_GRID := 2.0 # Building pieces snap to 2m grid
const PLACEMENT_RANGE := 8.0

var is_building := false
var current_piece_id := ""
var ghost_piece: Node3D
var placed_pieces: Array[Dictionary] = []
var player: CharacterBody3D

# Building piece definitions
var piece_defs := {
	"wattle_wall": {
		"size": Vector3(2.0, 2.5, 0.2),
		"color": Color(0.45, 0.38, 0.25),
		"snap_type": "wall",
		"stability": true
	},
	"thatch_roof": {
		"size": Vector3(2.0, 0.15, 2.0),
		"color": Color(0.4, 0.35, 0.18),
		"snap_type": "roof",
		"stability": true
	},
	"wooden_floor": {
		"size": Vector3(2.0, 0.1, 2.0),
		"color": Color(0.35, 0.25, 0.15),
		"snap_type": "floor",
		"stability": true
	},
	"wooden_door": {
		"size": Vector3(1.0, 2.0, 0.15),
		"color": Color(0.3, 0.2, 0.1),
		"snap_type": "wall",
		"stability": false
	},
	"fire_pit": {
		"size": Vector3(1.0, 0.3, 1.0),
		"color": Color(0.3, 0.25, 0.2),
		"snap_type": "free",
		"stability": false,
		"station": "fire"
	},
	"workbench": {
		"size": Vector3(1.5, 1.0, 0.8),
		"color": Color(0.4, 0.3, 0.15),
		"snap_type": "free",
		"stability": false,
		"station": "workbench"
	},
	"forge": {
		"size": Vector3(1.5, 1.5, 1.5),
		"color": Color(0.35, 0.3, 0.25),
		"snap_type": "free",
		"stability": false,
		"station": "forge"
	},
	"bed": {
		"size": Vector3(1.0, 0.5, 2.0),
		"color": Color(0.4, 0.3, 0.2),
		"snap_type": "free",
		"stability": false,
		"station": "bed"
	},
}

func _ready() -> void:
	set_process_unhandled_input(true)

func set_player(p: CharacterBody3D) -> void:
	player = p

func _unhandled_input(event: InputEvent) -> void:
	if not is_building:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_place_piece()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel_building()

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			_rotate_ghost(-PI / 4.0)
		elif event.keycode == KEY_E:
			_rotate_ghost(PI / 4.0)

func _process(delta: float) -> void:
	if is_building and ghost_piece and player:
		_update_ghost_position()

func enter_build_mode(piece_id: String) -> void:
	if piece_id not in piece_defs:
		return

	current_piece_id = piece_id
	is_building = true

	# Create ghost preview
	_create_ghost(piece_id)
	build_mode_changed.emit(true)

func exit_build_mode() -> void:
	is_building = false
	current_piece_id = ""
	if ghost_piece:
		ghost_piece.queue_free()
		ghost_piece = null
	build_mode_changed.emit(false)

func _create_ghost(piece_id: String) -> void:
	if ghost_piece:
		ghost_piece.queue_free()

	var def := piece_defs[piece_id]
	ghost_piece = MeshInstance3D.new()
	ghost_piece.name = "BuildGhost"

	var mesh := BoxMesh.new()
	mesh.size = def.size
	(ghost_piece as MeshInstance3D).mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.8, 0.3, 0.4) # Green transparent
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	(ghost_piece as MeshInstance3D).material_override = mat

	ghost_piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Add to scene root so it's visible everywhere
	get_tree().root.add_child(ghost_piece)

func _update_ghost_position() -> void:
	if not ghost_piece or not player:
		return

	var camera := player.get_viewport().get_camera_3d()
	if not camera:
		return

	# Raycast from camera center
	var viewport_center := player.get_viewport().get_visible_rect().size / 2.0
	var from := camera.project_ray_origin(viewport_center)
	var to := from + camera.project_ray_normal(viewport_center) * PLACEMENT_RANGE

	var space := player.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to, 1) # Static world
	var result := space.intersect_ray(query)

	if result:
		var pos := result.position
		var def := piece_defs[current_piece_id]

		# Snap to grid
		if def.snap_type != "free":
			pos.x = snapped(pos.x, SNAP_GRID)
			pos.z = snapped(pos.z, SNAP_GRID)

		# Offset for piece height
		if def.snap_type == "wall":
			pos.y += def.size.y / 2.0
		elif def.snap_type == "roof":
			pos.y += 2.5 # Wall height
		# floor stays at ground level

		ghost_piece.position = pos

		# Color based on validity
		var mat: StandardMaterial3D = (ghost_piece as MeshInstance3D).material_override
		if _can_place_at(pos):
			mat.albedo_color = Color(0.3, 0.8, 0.3, 0.4) # Green
		else:
			mat.albedo_color = Color(0.8, 0.3, 0.3, 0.4) # Red

func _can_place_at(pos: Vector3) -> bool:
	if not player:
		return false

	# Check distance from player
	if player.global_position.distance_to(pos) > PLACEMENT_RANGE:
		return false

	# Check not underwater (except fire pit can't be, others can)
	if pos.y < 0.0 and current_piece_id != "wooden_floor":
		return false

	return true

func _place_piece() -> void:
	if not ghost_piece or not player:
		return

	var pos := ghost_piece.position
	if not _can_place_at(pos):
		return

	# Check inventory for piece
	var inventory := player.get_node_or_null("Inventory")
	if inventory and not inventory.has_item(current_piece_id):
		return

	# Consume item
	if inventory:
		inventory.remove_item(current_piece_id)

	# Create actual piece
	var def := piece_defs[current_piece_id]
	var piece := MeshInstance3D.new()
	piece.name = "Built_%s" % current_piece_id

	var mesh := BoxMesh.new()
	mesh.size = def.size
	piece.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = def.color
	mat.roughness = 0.85
	piece.material_override = mat

	piece.position = pos
	piece.rotation = ghost_piece.rotation

	# Add collision
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = def.size
	col.shape = shape
	body.add_child(col)
	piece.add_child(body)

	# If it's a station, add interaction
	if "station" in def:
		body.set_meta("station_type", def.station)

	# Add light for fire pit
	if current_piece_id == "fire_pit":
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.6, 0.2)
		light.light_energy = 2.0
		light.omni_range = 8.0
		light.position.y = 0.5
		piece.add_child(light)

		# Fire particles placeholder
		var fire := MeshInstance3D.new()
		var fire_mesh := SphereMesh.new()
		fire_mesh.radius = 0.2
		fire_mesh.height = 0.5
		fire.mesh = fire_mesh
		var fire_mat := StandardMaterial3D.new()
		fire_mat.albedo_color = Color(1.0, 0.5, 0.1)
		fire_mat.emission_enabled = true
		fire_mat.emission = Color(1.0, 0.4, 0.1)
		fire_mat.emission_energy_multiplier = 3.0
		fire.material_override = fire_mat
		fire.position.y = 0.3
		piece.add_child(fire)

	get_tree().root.add_child(piece)

	placed_pieces.append({
		"id": current_piece_id,
		"position": pos,
		"rotation": ghost_piece.rotation,
		"node": piece
	})

	piece_placed.emit(current_piece_id, pos)

func _cancel_building() -> void:
	exit_build_mode()

func _rotate_ghost(angle: float) -> void:
	if ghost_piece:
		ghost_piece.rotation.y += angle

func get_nearby_station(pos: Vector3, radius: float = 5.0) -> String:
	for piece in placed_pieces:
		if piece.position.distance_to(pos) <= radius:
			var def = piece_defs.get(piece.id, {})
			if "station" in def:
				return def.station
	return ""

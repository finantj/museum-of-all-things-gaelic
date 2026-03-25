extends Node3D
## Places historically significant structures around Lough Key.
## - Castle Island (The Rock) - MacDermot fortress
## - Trinity Island - Premonstratensian monastery
## - Crannogs and ring forts

const CASTLE_ISLAND_POS := Vector3(95.0, 3.5, 105.0)
const TRINITY_ISLAND_POS := Vector3(88.0, 2.5, 92.0)

func _ready() -> void:
	call_deferred("_build_all")

func _build_all() -> void:
	_build_macdermot_castle()
	_build_trinity_monastery()
	_build_ringfort(Vector3(130.0, 4.0, 80.0), "Rath_Mor")
	_build_ringfort(Vector3(160.0, 6.0, 130.0), "Rath_Beag")
	_build_crannog(Vector3(75.0, 0.3, 108.0))
	_build_crannog(Vector3(110.0, 0.3, 88.0))
	_build_village(Vector3(140.0, 3.0, 100.0))

func _build_macdermot_castle() -> void:
	var castle := Node3D.new()
	castle.name = "MacDermotCastle"
	castle.position = CASTLE_ISLAND_POS

	var stone_color := Color(0.45, 0.42, 0.38)
	var dark_stone := Color(0.3, 0.28, 0.25)

	# Main keep - rectangular tower house
	var keep := _create_box(Vector3(6.0, 10.0, 5.0), stone_color)
	keep.position.y = 5.0
	castle.add_child(keep)

	# Keep battlements
	for i in range(4):
		for j in range(3):
			if (i + j) % 2 == 0:
				var merlon := _create_box(Vector3(0.8, 1.2, 0.8), dark_stone)
				merlon.position = Vector3(-2.5 + i * 1.8, 10.6, -1.8 + j * 1.8)
				castle.add_child(merlon)

	# Curtain wall (encircling the keep)
	var wall_segments := 12
	var wall_radius := 10.0
	for i in range(wall_segments):
		var angle := float(i) / wall_segments * TAU
		var next_angle := float(i + 1) / wall_segments * TAU
		var pos := Vector3(cos(angle) * wall_radius, 3.0, sin(angle) * wall_radius)

		var wall := _create_box(Vector3(5.5, 6.0, 1.0), stone_color)
		wall.position = pos
		wall.rotation.y = -angle + PI / 2.0
		castle.add_child(wall)

	# Corner towers (round)
	for i in range(4):
		var angle := float(i) / 4.0 * TAU + PI / 4.0
		var tower := _create_cylinder(1.5, 8.0, dark_stone)
		tower.position = Vector3(cos(angle) * wall_radius, 4.0, sin(angle) * wall_radius)
		castle.add_child(tower)

		# Tower cap (cone)
		var cap := _create_cone(2.0, 3.0, Color(0.25, 0.2, 0.15))
		cap.position = Vector3(cos(angle) * wall_radius, 9.5, sin(angle) * wall_radius)
		castle.add_child(cap)

	# Gatehouse
	var gatehouse := _create_box(Vector3(4.0, 7.0, 3.0), dark_stone)
	gatehouse.position = Vector3(wall_radius, 3.5, 0.0)
	castle.add_child(gatehouse)

	# Gate arch (simple opening representation)
	var gate_arch := _create_box(Vector3(2.0, 4.0, 3.2), Color(0.1, 0.08, 0.06))
	gate_arch.position = Vector3(wall_radius, 2.0, 0.0)
	castle.add_child(gate_arch)

	# MacDermot banner pole
	var pole := _create_cylinder(0.05, 4.0, Color(0.3, 0.2, 0.1))
	pole.position = Vector3(0.0, 12.0, 0.0)
	castle.add_child(pole)

	# Banner (simple quad)
	var banner := _create_box(Vector3(1.5, 1.0, 0.05), Color(0.6, 0.15, 0.1)) # Red - MacDermot colors
	banner.position = Vector3(0.75, 12.5, 0.0)
	castle.add_child(banner)

	# Great hall inside walls
	var hall := _create_box(Vector3(8.0, 4.0, 5.0), Color(0.4, 0.35, 0.3))
	hall.position = Vector3(-3.0, 2.0, -3.0)
	castle.add_child(hall)

	# Thatched roof for hall
	var roof := _create_box(Vector3(9.0, 0.5, 6.0), Color(0.4, 0.35, 0.2))
	roof.position = Vector3(-3.0, 4.5, -3.0)
	roof.rotation.x = deg_to_rad(5.0)
	castle.add_child(roof)

	# Add collision for the whole castle
	_add_compound_collision(castle)

	add_child(castle)

func _build_trinity_monastery() -> void:
	var monastery := Node3D.new()
	monastery.name = "TrinityMonastery"
	monastery.position = TRINITY_ISLAND_POS

	var stone := Color(0.5, 0.48, 0.42)

	# Church nave
	var nave := _create_box(Vector3(4.0, 5.0, 10.0), stone)
	nave.position.y = 2.5
	monastery.add_child(nave)

	# Church roof (peaked)
	var roof := _create_box(Vector3(4.5, 0.3, 10.5), Color(0.3, 0.28, 0.22))
	roof.position = Vector3(0.0, 5.5, 0.0)
	roof.rotation.z = deg_to_rad(25.0)
	monastery.add_child(roof)
	var roof2 := _create_box(Vector3(4.5, 0.3, 10.5), Color(0.3, 0.28, 0.22))
	roof2.position = Vector3(0.0, 5.5, 0.0)
	roof2.rotation.z = deg_to_rad(-25.0)
	monastery.add_child(roof2)

	# Bell tower
	var tower := _create_box(Vector3(2.0, 8.0, 2.0), stone)
	tower.position = Vector3(0.0, 4.0, -5.5)
	monastery.add_child(tower)

	# Tower roof (pyramid)
	var tower_roof := _create_cone(1.8, 2.5, Color(0.3, 0.28, 0.2))
	tower_roof.position = Vector3(0.0, 9.5, -5.5)
	monastery.add_child(tower_roof)

	# Cloister (square of lower buildings)
	for side in range(4):
		var cloister := _create_box(Vector3(6.0, 2.5, 1.5), Color(0.45, 0.42, 0.38))
		var angle := side * PI / 2.0
		cloister.position = Vector3(
			cos(angle) * 4.0,
			1.25,
			sin(angle) * 4.0 + 5.0
		)
		cloister.rotation.y = angle
		monastery.add_child(cloister)

	# Stone cross in front
	var cross_base := _create_cylinder(0.3, 0.5, stone)
	cross_base.position = Vector3(4.0, 0.25, 0.0)
	monastery.add_child(cross_base)

	var cross_shaft := _create_box(Vector3(0.3, 3.0, 0.3), stone)
	cross_shaft.position = Vector3(4.0, 2.0, 0.0)
	monastery.add_child(cross_shaft)

	var cross_arm := _create_box(Vector3(1.5, 0.3, 0.3), stone)
	cross_arm.position = Vector3(4.0, 3.0, 0.0)
	monastery.add_child(cross_arm)

	# Celtic ring on cross
	var ring := _create_torus(0.5, 0.08, stone)
	ring.position = Vector3(4.0, 3.0, 0.0)
	monastery.add_child(ring)

	_add_compound_collision(monastery)
	add_child(monastery)

func _build_ringfort(pos: Vector3, fort_name: String) -> void:
	var fort := Node3D.new()
	fort.name = fort_name
	fort.position = pos

	var earth_color := Color(0.3, 0.25, 0.15)

	# Earthen bank (ring)
	var segments := 24
	var radius := 8.0
	for i in range(segments):
		var angle := float(i) / segments * TAU
		var bank := _create_box(Vector3(2.5, 1.5, 1.5), earth_color)
		bank.position = Vector3(cos(angle) * radius, 0.75, sin(angle) * radius)
		bank.rotation.y = -angle
		fort.add_child(bank)

	# Central dwelling
	var dwelling := _create_cylinder(3.0, 3.0, Color(0.35, 0.25, 0.12))
	dwelling.position.y = 1.5
	fort.add_child(dwelling)

	# Thatched roof
	var roof := _create_cone(3.5, 2.5, Color(0.45, 0.4, 0.2))
	roof.position.y = 4.0
	fort.add_child(roof)

	_add_compound_collision(fort)
	add_child(fort)

func _build_crannog(pos: Vector3) -> void:
	var crannog := Node3D.new()
	crannog.name = "Crannog"
	crannog.position = pos

	# Wooden platform on lake
	var platform := _create_cylinder(5.0, 0.3, Color(0.35, 0.25, 0.12))
	platform.position.y = 0.5
	crannog.add_child(platform)

	# Support posts
	for i in range(8):
		var angle := float(i) / 8.0 * TAU
		var post := _create_cylinder(0.15, 3.0, Color(0.3, 0.2, 0.1))
		post.position = Vector3(cos(angle) * 4.0, -1.0, sin(angle) * 4.0)
		crannog.add_child(post)

	# Small roundhouse on platform
	var house := _create_cylinder(2.0, 2.5, Color(0.4, 0.3, 0.15))
	house.position.y = 2.0
	crannog.add_child(house)

	var roof := _create_cone(2.5, 2.0, Color(0.45, 0.4, 0.2))
	roof.position.y = 4.5
	crannog.add_child(roof)

	# Palisade
	for i in range(16):
		var angle := float(i) / 16.0 * TAU
		var stake := _create_cylinder(0.08, 2.0, Color(0.3, 0.2, 0.1))
		stake.position = Vector3(cos(angle) * 4.5, 1.5, sin(angle) * 4.5)
		crannog.add_child(stake)

	_add_compound_collision(crannog)
	add_child(crannog)

func _build_village(pos: Vector3) -> void:
	var village := Node3D.new()
	village.name = "ClachanVillage"
	village.position = pos

	# Irish clachan - cluster of small houses
	var house_positions := [
		Vector3(0, 0, 0), Vector3(5, 0, 2), Vector3(-3, 0, 5),
		Vector3(7, 0, -3), Vector3(-5, 0, -2), Vector3(2, 0, -5),
		Vector3(10, 0, 1), Vector3(-1, 0, 8)
	]

	for i in range(house_positions.size()):
		var house := _create_roundhouse(i)
		house.position = house_positions[i]
		village.add_child(house)

	# Central fire pit
	var fire_pit := _create_cylinder(1.0, 0.2, Color(0.2, 0.15, 0.1))
	fire_pit.position = Vector3(2.0, 0.1, 1.0)
	village.add_child(fire_pit)

	# Fire light
	var fire_light := OmniLight3D.new()
	fire_light.light_color = Color(1.0, 0.6, 0.2)
	fire_light.light_energy = 2.0
	fire_light.omni_range = 8.0
	fire_light.position = Vector3(2.0, 1.0, 1.0)
	village.add_child(fire_light)

	_add_compound_collision(village)
	add_child(village)

func _create_roundhouse(index: int) -> Node3D:
	var house := Node3D.new()
	house.name = "Roundhouse_%d" % index

	var rng_local := RandomNumberGenerator.new()
	rng_local.seed = 1250 + index

	var radius := rng_local.randf_range(1.5, 2.5)
	var wall_height := rng_local.randf_range(2.0, 2.8)

	# Wattle and daub walls
	var walls := _create_cylinder(radius, wall_height, Color(0.45, 0.38, 0.25))
	walls.position.y = wall_height / 2.0
	house.add_child(walls)

	# Thatched cone roof
	var roof := _create_cone(radius + 0.5, wall_height * 0.8, Color(0.4, 0.35, 0.18))
	roof.position.y = wall_height + wall_height * 0.4
	house.add_child(roof)

	# Doorway (dark opening)
	var door := _create_box(Vector3(0.7, 1.5, 0.3), Color(0.08, 0.06, 0.04))
	door.position = Vector3(radius - 0.1, 0.75, 0.0)
	house.add_child(door)

	house.rotation.y = rng_local.randf() * TAU
	return house

# Helper functions to create basic meshes with materials
func _create_box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mesh_inst.material_override = mat

	return mesh_inst

func _create_cylinder(radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh_inst.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mesh_inst.material_override = mat

	return mesh_inst

func _create_cone(radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.01
	mesh.bottom_radius = radius
	mesh.height = height
	mesh_inst.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mesh_inst.material_override = mat

	return mesh_inst

func _create_torus(major_radius: float, minor_radius: float, color: Color) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = major_radius - minor_radius
	mesh.outer_radius = major_radius + minor_radius
	mesh_inst.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mesh_inst.material_override = mat

	return mesh_inst

func _add_compound_collision(node: Node3D) -> void:
	# Add a simplified collision body for the structure
	var body := StaticBody3D.new()
	body.name = "Collision"

	for child in node.get_children():
		if child is MeshInstance3D:
			var col := CollisionShape3D.new()
			var mesh := child.mesh

			if mesh is BoxMesh:
				var shape := BoxShape3D.new()
				shape.size = mesh.size
				col.shape = shape
			elif mesh is CylinderMesh:
				var shape := CylinderShape3D.new()
				shape.radius = mesh.bottom_radius
				shape.height = mesh.height
				col.shape = shape
			else:
				continue

			col.position = child.position
			col.rotation = child.rotation
			body.add_child(col)

	node.add_child(body)

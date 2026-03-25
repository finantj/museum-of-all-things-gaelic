extends CharacterBody3D
## Third-person player controller in the style of Valheim.
## WASD movement, mouse-look camera orbit, sprint, jump, dodge roll.

@export var walk_speed := 4.0
@export var run_speed := 7.0
@export var swim_speed := 2.5
@export var jump_force := 6.0
@export var dodge_force := 8.0
@export var gravity := 20.0
@export var mouse_sensitivity := 0.003
@export var gamepad_sensitivity := 2.5
@export var camera_distance := 5.0
@export var camera_min_distance := 2.0
@export var camera_max_distance := 12.0

const WATER_LEVEL := 0.0
const STAMINA_SPRINT := 8.0 # per second
const STAMINA_JUMP := 10.0
const STAMINA_DODGE := 15.0
const STAMINA_SWIM := 5.0 # per second
const STAMINA_ATTACK := 12.0

# Node references
var camera_pivot: Node3D
var camera_arm: SpringArm3D
var camera: Camera3D
var model: Node3D
var animation_player: AnimationPlayer
var stats: Node
var combat: Node
var interact_ray: RayCast3D
var inventory: Node

# State
var camera_rotation := Vector2(0.0, -0.3)
var is_running := false
var is_swimming := false
var is_dodging := false
var dodge_timer := 0.0
var dodge_direction := Vector3.ZERO
var is_attacking := false
var attack_timer := 0.0
var current_speed := 0.0

func _ready() -> void:
	_setup_player_model()
	_setup_camera()
	_setup_collision()
	_setup_systems()

func _setup_player_model() -> void:
	model = Node3D.new()
	model.name = "PlayerModel"

	# Viking/Gaelic warrior placeholder model
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.6
	body.mesh = capsule
	body.position.y = 0.8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.5, 0.35)
	mat.roughness = 0.8
	body.material_override = mat
	model.add_child(body)

	# Head
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	head.mesh = sphere
	head.position.y = 1.75
	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.75, 0.6, 0.5)
	head.material_override = skin_mat
	model.add_child(head)

	# Leine (Irish tunic)
	var tunic := MeshInstance3D.new()
	var tunic_mesh := CylinderMesh.new()
	tunic_mesh.top_radius = 0.32
	tunic_mesh.bottom_radius = 0.45
	tunic_mesh.height = 0.9
	tunic.mesh = tunic_mesh
	tunic.position.y = 0.55
	var tunic_mat := StandardMaterial3D.new()
	tunic_mat.albedo_color = Color(0.7, 0.65, 0.5) # Undyed linen
	tunic.material_override = tunic_mat
	model.add_child(tunic)

	# Brat (cloak)
	var cloak := MeshInstance3D.new()
	var cloak_mesh := BoxMesh.new()
	cloak_mesh.size = Vector3(0.7, 0.8, 0.15)
	cloak.mesh = cloak_mesh
	cloak.position = Vector3(0.0, 1.1, -0.15)
	var cloak_mat := StandardMaterial3D.new()
	cloak_mat.albedo_color = Color(0.3, 0.45, 0.25) # Green wool
	cloak.material_override = cloak_mat
	model.add_child(cloak)

	add_child(model)

func _setup_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position.y = 1.5

	camera_arm = SpringArm3D.new()
	camera_arm.name = "SpringArm"
	camera_arm.spring_length = camera_distance
	camera_arm.collision_mask = 1 # Static world
	camera_arm.margin = 0.3

	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.fov = 65.0
	camera.near = 0.1
	camera.far = 500.0

	camera_arm.add_child(camera)
	camera_pivot.add_child(camera_arm)
	add_child(camera_pivot)

func _setup_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	col.shape = shape
	col.position.y = 0.9
	add_child(col)

	# Interaction raycast
	interact_ray = RayCast3D.new()
	interact_ray.name = "InteractRay"
	interact_ray.target_position = Vector3(0, 0, -3.0)
	interact_ray.collision_mask = 2 | 4 # Dynamic + Pickable
	interact_ray.position.y = 1.2
	add_child(interact_ray)

func _setup_systems() -> void:
	# Player stats
	stats = preload("res://scenes/medieval/player/player_stats.gd").new()
	stats.name = "PlayerStats"
	add_child(stats)

	# Combat system
	combat = preload("res://scenes/medieval/player/combat_system.gd").new()
	combat.name = "CombatSystem"
	add_child(combat)

	# Inventory
	inventory = preload("res://scenes/medieval/systems/inventory.gd").new()
	inventory.name = "Inventory"
	add_child(inventory)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_rotation.x -= event.relative.x * mouse_sensitivity
		camera_rotation.y -= event.relative.y * mouse_sensitivity
		camera_rotation.y = clamp(camera_rotation.y, -1.2, 0.8)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(camera_min_distance, camera_distance - 0.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(camera_max_distance, camera_distance + 0.5)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_attack()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_block_start()
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			_block_end()

	if event.is_action_pressed("interact"):
		_interact()
	if event.is_action_pressed("jump"):
		if is_swimming:
			velocity.y = jump_force * 0.5
		elif is_on_floor() and stats.use_stamina(STAMINA_JUMP):
			velocity.y = jump_force

func _physics_process(delta: float) -> void:
	_update_camera(delta)
	_update_swimming()

	if is_dodging:
		_process_dodge(delta)
		move_and_slide()
		return

	# Movement input
	var input_dir := Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_back")

	# Gamepad camera
	var cam_input := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	camera_rotation.x -= cam_input.x * gamepad_sensitivity * delta
	camera_rotation.y -= cam_input.y * gamepad_sensitivity * delta
	camera_rotation.y = clamp(camera_rotation.y, -1.2, 0.8)

	# Direction relative to camera
	var cam_basis := Basis(Vector3.UP, camera_rotation.x)
	var direction := cam_basis * Vector3(input_dir.x, 0, input_dir.y)
	direction = direction.normalized()

	# Sprint
	is_running = Input.is_action_pressed("dash") and direction.length() > 0.1
	if is_running and not stats.has_stamina(STAMINA_SPRINT * delta):
		is_running = false
	if is_running:
		stats.use_stamina(STAMINA_SPRINT * delta)

	# Speed
	var target_speed: float
	if is_swimming:
		target_speed = swim_speed
		if is_running:
			stats.use_stamina(STAMINA_SWIM * delta)
	elif is_running:
		target_speed = run_speed
	else:
		target_speed = walk_speed

	# Apply movement
	if direction.length() > 0.1:
		velocity.x = direction.x * target_speed
		velocity.z = direction.z * target_speed

		# Rotate model to face movement direction
		var look_dir := Vector3(direction.x, 0, direction.z)
		if look_dir.length() > 0.1:
			var target_angle := atan2(look_dir.x, look_dir.z)
			model.rotation.y = lerp_angle(model.rotation.y, target_angle, 10.0 * delta)

		current_speed = target_speed
	else:
		velocity.x = move_toward(velocity.x, 0, target_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0, target_speed * 8.0 * delta)
		current_speed = 0.0

	# Gravity / buoyancy
	if is_swimming:
		if position.y < WATER_LEVEL - 0.5:
			velocity.y += 8.0 * delta # Buoyancy
		else:
			velocity.y = move_toward(velocity.y, 0.0, 5.0 * delta)
	elif not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()

	# Update interact ray direction
	interact_ray.target_position = -model.transform.basis.z * 3.0

func _update_camera(delta: float) -> void:
	camera_pivot.rotation = Vector3(camera_rotation.y, camera_rotation.x, 0)
	camera_arm.spring_length = lerp(camera_arm.spring_length, camera_distance, 5.0 * delta)

func _update_swimming() -> void:
	var was_swimming := is_swimming
	is_swimming = position.y < WATER_LEVEL - 0.3

	if is_swimming and not was_swimming:
		# Entered water
		velocity.y *= 0.3

func _attack() -> void:
	if is_attacking or not stats.use_stamina(STAMINA_ATTACK):
		return
	is_attacking = true
	attack_timer = 0.5

	if combat:
		combat.perform_attack(model.global_transform.basis.z * -1.0)

	# Reset after swing
	get_tree().create_timer(0.5).timeout.connect(func(): is_attacking = false)

func _block_start() -> void:
	if combat:
		combat.start_blocking()

func _block_end() -> void:
	if combat:
		combat.stop_blocking()

func _interact() -> void:
	if interact_ray.is_colliding():
		var target := interact_ray.get_collider()
		if target.has_method("interact"):
			target.interact(self)
		elif target.get_parent().has_method("interact"):
			target.get_parent().interact(self)

func _process_dodge(delta: float) -> void:
	dodge_timer -= delta
	velocity = dodge_direction * dodge_force
	if not is_on_floor():
		velocity.y -= gravity * delta

	if dodge_timer <= 0:
		is_dodging = false

func dodge() -> void:
	if is_dodging or not stats.use_stamina(STAMINA_DODGE):
		return

	var input_dir := Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_back")
	if input_dir.length() < 0.1:
		input_dir = Vector2(0, 1) # Dodge backward by default

	var cam_basis := Basis(Vector3.UP, camera_rotation.x)
	dodge_direction = cam_basis * Vector3(input_dir.x, 0, input_dir.y)
	dodge_direction = dodge_direction.normalized()

	is_dodging = true
	dodge_timer = 0.3

extends Node
## Melee combat system - sword, axe, spear combat with blocking and parrying.

signal attack_performed(damage: float, direction: Vector3)
signal blocked()
signal parried()
signal weapon_changed(weapon_name: String)

enum WeaponType { FIST, SWORD, AXE, SPEAR, BOW }
enum AttackState { IDLE, WINDUP, SWING, RECOVERY }

# Current weapon
var current_weapon := WeaponType.FIST
var weapon_data := {}

# Combat state
var attack_state := AttackState.IDLE
var is_blocking := false
var block_timer := 0.0
var parry_window := 0.2 # Seconds for perfect parry
var attack_cooldown := 0.0
var combo_count := 0
var combo_timer := 0.0
var combo_max := 3

# Weapon stats database
var weapons := {
	WeaponType.FIST: {
		"name": "Fists",
		"damage": 3.0,
		"speed": 0.4,
		"range": 1.5,
		"stamina": 5.0,
		"block_reduction": 0.2,
		"knockback": 1.0
	},
	WeaponType.SWORD: {
		"name": "Claidheamh", # Irish sword
		"damage": 12.0,
		"speed": 0.6,
		"range": 2.5,
		"stamina": 12.0,
		"block_reduction": 0.6,
		"knockback": 3.0
	},
	WeaponType.AXE: {
		"name": "Tua", # Irish axe
		"damage": 18.0,
		"speed": 0.9,
		"range": 2.0,
		"stamina": 18.0,
		"block_reduction": 0.4,
		"knockback": 5.0
	},
	WeaponType.SPEAR: {
		"name": "Sleagh", # Irish spear
		"damage": 15.0,
		"speed": 0.7,
		"range": 3.5,
		"stamina": 14.0,
		"block_reduction": 0.3,
		"knockback": 4.0
	},
	WeaponType.BOW: {
		"name": "Bogha", # Irish bow
		"damage": 10.0,
		"speed": 1.2,
		"range": 30.0,
		"stamina": 10.0,
		"block_reduction": 0.0,
		"knockback": 2.0
	}
}

var weapon_model: MeshInstance3D
var attack_area: Area3D

func _ready() -> void:
	weapon_data = weapons[current_weapon]
	_create_weapon_model()
	_create_attack_area()

func _process(delta: float) -> void:
	if attack_cooldown > 0:
		attack_cooldown -= delta

	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0

	if is_blocking:
		block_timer += delta

func _create_weapon_model() -> void:
	weapon_model = MeshInstance3D.new()
	weapon_model.name = "WeaponModel"
	_update_weapon_visual()

	# Position in right hand
	weapon_model.position = Vector3(0.35, 1.0, -0.3)
	weapon_model.visible = current_weapon != WeaponType.FIST

	var player_model = get_parent().get_node_or_null("PlayerModel")
	if player_model:
		player_model.add_child(weapon_model)

func _create_attack_area() -> void:
	attack_area = Area3D.new()
	attack_area.name = "AttackArea"
	attack_area.collision_layer = 0
	attack_area.collision_mask = 2 # Dynamic world

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 1.0, weapon_data.range)
	shape.shape = box
	shape.position.z = -weapon_data.range / 2.0

	attack_area.add_child(shape)
	attack_area.monitoring = false

	var player_model = get_parent().get_node_or_null("PlayerModel")
	if player_model:
		attack_area.position.y = 1.0
		player_model.add_child(attack_area)

func perform_attack(direction: Vector3) -> void:
	if attack_cooldown > 0 or is_blocking:
		return

	attack_state = AttackState.SWING
	attack_cooldown = weapon_data.speed

	# Combo tracking
	combo_count = (combo_count + 1) % (combo_max + 1)
	combo_timer = 1.0

	# Damage multiplier for combo
	var damage_mult := 1.0 + combo_count * 0.15

	# Check for hits
	attack_area.monitoring = true

	# Damage anything in range
	var final_damage := weapon_data.damage * damage_mult
	attack_performed.emit(final_damage, direction)

	# Check overlapping bodies
	for body in attack_area.get_overlapping_bodies():
		if body != get_parent() and body.has_method("take_damage"):
			body.take_damage(final_damage, direction * weapon_data.knockback)

	# Disable after swing
	get_tree().create_timer(0.15).timeout.connect(func():
		attack_area.monitoring = false
		attack_state = AttackState.RECOVERY
	)

	get_tree().create_timer(weapon_data.speed).timeout.connect(func():
		attack_state = AttackState.IDLE
	)

func start_blocking() -> void:
	if attack_state != AttackState.IDLE:
		return
	is_blocking = true
	block_timer = 0.0

func stop_blocking() -> void:
	is_blocking = false
	block_timer = 0.0

func receive_attack(damage: float, direction: Vector3) -> float:
	if is_blocking:
		var reduced := damage * (1.0 - weapon_data.block_reduction)
		if block_timer <= parry_window:
			parried.emit()
			return 0.0 # Perfect parry
		blocked.emit()
		return reduced
	return damage

func equip_weapon(type: WeaponType) -> void:
	current_weapon = type
	weapon_data = weapons[type]
	_update_weapon_visual()
	weapon_changed.emit(weapon_data.name)
	weapon_model.visible = type != WeaponType.FIST

func _update_weapon_visual() -> void:
	if not weapon_model:
		return

	match current_weapon:
		WeaponType.SWORD:
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.06, 0.8, 0.02)
			weapon_model.mesh = mesh
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.7, 0.7, 0.75)
			mat.metallic = 0.8
			mat.roughness = 0.3
			weapon_model.material_override = mat
		WeaponType.AXE:
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.15, 0.6, 0.03)
			weapon_model.mesh = mesh
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.5, 0.45, 0.4)
			mat.metallic = 0.4
			weapon_model.material_override = mat
		WeaponType.SPEAR:
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.015
			mesh.bottom_radius = 0.02
			mesh.height = 2.0
			weapon_model.mesh = mesh
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.4, 0.3, 0.2)
			weapon_model.material_override = mat
		_:
			weapon_model.mesh = null

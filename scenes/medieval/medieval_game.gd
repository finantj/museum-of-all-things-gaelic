extends Node3D
## Main controller for the Medieval Ireland game.
## Builds the full game world around Lough Key, County Roscommon, c. 1250 AD.

const WORLD_SEED := 1250 # Year-based seed for deterministic generation

@onready var world: Node3D
@onready var player: CharacterBody3D
@onready var hud: CanvasLayer
@onready var day_night: Node
@onready var pause_menu: Control

var is_paused := false
var game_started := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Build the world
	_build_world()
	_spawn_player()
	_setup_hud()
	_setup_pause_menu()

	game_started = true
	print("=== Lough Key, Moylurg - Anno Domini 1250 ===")
	print("The MacDermot lords bid you welcome.")

func _build_world() -> void:
	world = Node3D.new()
	world.name = "World"
	add_child(world)

	# Terrain
	var terrain_gen = preload("res://scenes/medieval/world/terrain_generator.gd").new()
	terrain_gen.name = "TerrainGenerator"
	world.add_child(terrain_gen)

	# Water (Lough Key)
	var water = preload("res://scenes/medieval/world/water_plane.gd").new()
	water.name = "LoughKey"
	world.add_child(water)

	# Day/Night cycle
	day_night = preload("res://scenes/medieval/world/day_night_cycle.gd").new()
	day_night.name = "DayNightCycle"
	world.add_child(day_night)

	# Vegetation
	var veg = preload("res://scenes/medieval/world/vegetation_spawner.gd").new()
	veg.name = "Vegetation"
	world.add_child(veg)

	# Resource nodes (trees, stones, etc.)
	var resources = preload("res://scenes/medieval/systems/resource_spawner.gd").new()
	resources.name = "ResourceSpawner"
	world.add_child(resources)

	# NPCs
	var npc_spawner = preload("res://scenes/medieval/npcs/npc_spawner.gd").new()
	npc_spawner.name = "NPCSpawner"
	world.add_child(npc_spawner)

	# Structures (Castle Island, Trinity Island monastery)
	var structures = preload("res://scenes/medieval/world/historic_structures.gd").new()
	structures.name = "HistoricStructures"
	world.add_child(structures)

func _spawn_player() -> void:
	var player_scene = preload("res://scenes/medieval/player/player_controller.tscn")
	player = player_scene.instantiate()
	player.name = "Player"
	# Spawn on the eastern shore of Lough Key
	player.position = Vector3(80.0, 0.0, 60.0)
	add_child(player)

func _setup_hud() -> void:
	var hud_scene = preload("res://scenes/medieval/ui/hud.tscn")
	hud = hud_scene.instantiate()
	hud.name = "HUD"
	add_child(hud)

	# Connect player stats to HUD
	if player.has_node("PlayerStats"):
		var stats = player.get_node("PlayerStats")
		stats.connect("health_changed", Callable(hud, "_on_health_changed"))
		stats.connect("stamina_changed", Callable(hud, "_on_stamina_changed"))
		stats.connect("hunger_changed", Callable(hud, "_on_hunger_changed"))

func _setup_pause_menu() -> void:
	pause_menu = preload("res://scenes/medieval/ui/pause_menu.gd").new()
	pause_menu.name = "PauseMenu"
	pause_menu.visible = false
	var canvas = CanvasLayer.new()
	canvas.name = "PauseLayer"
	canvas.layer = 10
	canvas.add_child(pause_menu)
	add_child(canvas)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
	if event.is_action_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

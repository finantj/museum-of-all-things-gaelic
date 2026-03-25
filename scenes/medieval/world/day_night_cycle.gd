extends Node
## Day/night cycle for medieval Ireland.
## Controls sun position, ambient light, and fog.

signal time_changed(hour: float)
signal period_changed(period: String)

const DAY_LENGTH_SECONDS := 1200.0 # 20 real minutes = 1 game day
const DAWN_HOUR := 6.0
const DUSK_HOUR := 20.0

var current_time := 8.0 # Start at 8 AM
var time_speed := 24.0 / DAY_LENGTH_SECONDS
var sun_light: DirectionalLight3D
var moon_light: DirectionalLight3D
var environment: WorldEnvironment
var current_period := "day"
var paused := false

# Irish weather - overcast skies are common
var overcast_factor := 0.3

func _ready() -> void:
	_create_sun()
	_create_moon()
	_create_environment()
	_update_lighting()

func _create_sun() -> void:
	sun_light = DirectionalLight3D.new()
	sun_light.name = "Sun"
	sun_light.light_color = Color(1.0, 0.95, 0.85)
	sun_light.light_energy = 1.2
	sun_light.shadow_enabled = true
	sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun_light.directional_shadow_max_distance = 150.0
	sun_light.light_angular_size = 0.5
	add_child(sun_light)

func _create_moon() -> void:
	moon_light = DirectionalLight3D.new()
	moon_light.name = "Moon"
	moon_light.light_color = Color(0.6, 0.65, 0.8)
	moon_light.light_energy = 0.0
	moon_light.shadow_enabled = true
	add_child(moon_light)

func _create_environment() -> void:
	environment = WorldEnvironment.new()
	environment.name = "WorldEnv"

	var env := Environment.new()

	# Sky - procedural for day/night transitions
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.35, 0.45, 0.55) # Irish grey-blue sky
	sky_mat.sky_horizon_color = Color(0.55, 0.6, 0.65)
	sky_mat.ground_bottom_color = Color(0.15, 0.18, 0.12)
	sky_mat.ground_horizon_color = Color(0.3, 0.35, 0.3)
	sky_mat.sun_angle_max = 30.0
	sky_mat.sun_curve = 0.15
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY

	# Ambient light - soft, diffuse (overcast Ireland)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.ambient_light_sky_contribution = 0.7

	# Fog - atmospheric Irish mist
	env.fog_enabled = true
	env.fog_light_color = Color(0.6, 0.65, 0.6)
	env.fog_density = 0.003
	env.fog_sky_affect = 0.5

	# Volumetric fog for atmosphere
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.015
	env.volumetric_fog_albedo = Color(0.7, 0.75, 0.7)
	env.volumetric_fog_emission = Color(0.1, 0.1, 0.1)
	env.volumetric_fog_length = 200.0

	# Tonemap
	env.tonemap_mode = Environment.TONE_MAP_ACES
	env.tonemap_exposure = 1.0

	# SSAO
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	env.ssao_intensity = 2.0

	# SSR (subtle)
	env.ssr_enabled = true
	env.ssr_max_steps = 64

	# Glow (subtle bloom)
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.1

	environment.environment = env
	add_child(environment)

func _process(delta: float) -> void:
	if paused:
		return

	current_time += time_speed * delta
	if current_time >= 24.0:
		current_time -= 24.0

	_update_lighting()
	time_changed.emit(current_time)

	var new_period := _get_period()
	if new_period != current_period:
		current_period = new_period
		period_changed.emit(current_period)

func _get_period() -> String:
	if current_time < 5.5:
		return "night"
	elif current_time < 7.0:
		return "dawn"
	elif current_time < 18.5:
		return "day"
	elif current_time < 20.5:
		return "dusk"
	else:
		return "night"

func _update_lighting() -> void:
	if not sun_light or not moon_light:
		return

	# Sun arc - rises in east, sets in west
	var sun_angle := (current_time - 12.0) / 12.0 * PI
	sun_light.rotation.x = -sun_angle
	sun_light.rotation.y = deg_to_rad(30.0) # Slight offset for Irish latitude (~53N)

	# Moon opposite to sun
	moon_light.rotation.x = -(sun_angle + PI)
	moon_light.rotation.y = deg_to_rad(-20.0)

	var period := _get_period()
	var env := environment.environment if environment else null

	match period:
		"night":
			sun_light.light_energy = 0.0
			moon_light.light_energy = 0.15
			if env:
				env.ambient_light_energy = 0.08
				env.fog_light_color = Color(0.1, 0.12, 0.15)
				env.volumetric_fog_density = 0.025
		"dawn":
			var t := (current_time - 5.5) / 1.5
			sun_light.light_energy = lerp(0.0, 0.8, t)
			sun_light.light_color = Color(1.0, 0.7, 0.4).lerp(Color(1.0, 0.95, 0.85), t)
			moon_light.light_energy = lerp(0.15, 0.0, t)
			if env:
				env.ambient_light_energy = lerp(0.08, 0.4, t)
				env.fog_light_color = Color(0.4, 0.35, 0.3).lerp(Color(0.6, 0.65, 0.6), t)
				env.volumetric_fog_density = lerp(0.025, 0.02, t)
		"day":
			sun_light.light_energy = lerp(0.8, 1.2, 1.0 - overcast_factor)
			sun_light.light_color = Color(1.0, 0.95, 0.85)
			moon_light.light_energy = 0.0
			if env:
				env.ambient_light_energy = lerp(0.4, 0.6, 1.0 - overcast_factor)
				env.fog_light_color = Color(0.6, 0.65, 0.6)
				env.volumetric_fog_density = lerp(0.01, 0.02, overcast_factor)
		"dusk":
			var t := (current_time - 18.5) / 2.0
			sun_light.light_energy = lerp(0.8, 0.0, t)
			sun_light.light_color = Color(1.0, 0.95, 0.85).lerp(Color(1.0, 0.5, 0.2), t)
			moon_light.light_energy = lerp(0.0, 0.15, t)
			if env:
				env.ambient_light_energy = lerp(0.4, 0.08, t)
				env.fog_light_color = Color(0.5, 0.4, 0.3).lerp(Color(0.1, 0.12, 0.15), t)
				env.volumetric_fog_density = lerp(0.015, 0.025, t)

func get_current_hour() -> float:
	return current_time

func is_daytime() -> bool:
	return current_time > DAWN_HOUR and current_time < DUSK_HOUR

func set_overcast(value: float) -> void:
	overcast_factor = clampf(value, 0.0, 1.0)

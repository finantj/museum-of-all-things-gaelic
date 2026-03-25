extends Node
## Player survival stats - Valheim-style health, stamina, hunger system.

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal hunger_changed(current: float, maximum: float)
signal player_died()
signal comfort_changed(level: int)

# Base stats
const BASE_HEALTH := 25.0
const BASE_STAMINA := 50.0
const MAX_HEALTH := 150.0
const MAX_STAMINA := 200.0
const MAX_HUNGER := 100.0

# Current values
var health := BASE_HEALTH
var max_health := BASE_HEALTH
var stamina := BASE_STAMINA
var max_stamina := BASE_STAMINA
var hunger := 80.0
var max_hunger := MAX_HUNGER

# Regen rates
var health_regen := 1.0 # HP per second
var stamina_regen := 8.0 # Stamina per second
var hunger_drain := 0.5 # Hunger points per minute

# Status
var is_dead := false
var is_resting := false
var comfort_level := 0 # 0-15, affects regen near shelter/fire
var is_wet := false
var is_cold := false
var is_sheltered := false

# Food buffs (up to 3 food items active, like Valheim)
var active_foods: Array[Dictionary] = []

func _ready() -> void:
	_emit_all()

func _process(delta: float) -> void:
	if is_dead:
		return

	_process_hunger(delta)
	_process_food_buffs(delta)
	_process_regen(delta)
	_process_environmental(delta)

func _process_hunger(delta: float) -> void:
	var drain := hunger_drain / 60.0 * delta
	if is_cold:
		drain *= 1.5
	hunger = max(0.0, hunger - drain)
	hunger_changed.emit(hunger, max_hunger)

	if hunger <= 0.0:
		take_damage(1.0 * delta) # Starving

func _process_food_buffs(delta: float) -> void:
	var bonus_health := 0.0
	var bonus_stamina := 0.0

	var expired: Array[int] = []
	for i in range(active_foods.size()):
		active_foods[i].time_remaining -= delta
		if active_foods[i].time_remaining <= 0:
			expired.append(i)
		else:
			# Diminishing returns as food wears off
			var ratio := active_foods[i].time_remaining / active_foods[i].duration
			bonus_health += active_foods[i].health_bonus * ratio
			bonus_stamina += active_foods[i].stamina_bonus * ratio

	# Remove expired foods (reverse order)
	expired.reverse()
	for idx in expired:
		active_foods.remove_at(idx)

	max_health = BASE_HEALTH + bonus_health
	max_stamina = BASE_STAMINA + bonus_stamina
	health = min(health, max_health)
	stamina = min(stamina, max_stamina)

func _process_regen(delta: float) -> void:
	# Health regen (only if hunger > 0)
	if hunger > 0 and health < max_health:
		var regen := health_regen * delta
		if is_resting:
			regen *= 3.0
		regen *= (1.0 + comfort_level * 0.1)
		health = min(max_health, health + regen)
		health_changed.emit(health, max_health)

	# Stamina regen
	if stamina < max_stamina:
		var regen := stamina_regen * delta
		if is_wet:
			regen *= 0.7
		if hunger <= 0:
			regen *= 0.3
		stamina = min(max_stamina, stamina + regen)
		stamina_changed.emit(stamina, max_stamina)

func _process_environmental(delta: float) -> void:
	# Cold/wet effects could be expanded with weather system
	pass

func take_damage(amount: float) -> void:
	if is_dead:
		return
	health = max(0.0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()

func heal(amount: float) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)

func use_stamina(amount: float) -> bool:
	if stamina >= amount:
		stamina -= amount
		stamina_changed.emit(stamina, max_stamina)
		return true
	return false

func has_stamina(amount: float) -> bool:
	return stamina >= amount

func eat_food(food_data: Dictionary) -> bool:
	# Valheim-style: max 3 foods, can't eat same type if already active
	if active_foods.size() >= 3:
		return false

	for food in active_foods:
		if food.name == food_data.name:
			return false

	var buff := {
		"name": food_data.get("name", "food"),
		"health_bonus": food_data.get("health_bonus", 10.0),
		"stamina_bonus": food_data.get("stamina_bonus", 10.0),
		"hunger_restore": food_data.get("hunger_restore", 20.0),
		"duration": food_data.get("duration", 300.0),
		"time_remaining": food_data.get("duration", 300.0)
	}

	active_foods.append(buff)
	hunger = min(max_hunger, hunger + buff.hunger_restore)
	hunger_changed.emit(hunger, max_hunger)
	return true

func set_comfort(level: int) -> void:
	comfort_level = clampi(level, 0, 15)
	comfort_changed.emit(comfort_level)

func _die() -> void:
	is_dead = true
	player_died.emit()

func respawn() -> void:
	is_dead = false
	health = BASE_HEALTH
	max_health = BASE_HEALTH
	stamina = BASE_STAMINA
	max_stamina = BASE_STAMINA
	hunger = 80.0
	active_foods.clear()
	_emit_all()

func _emit_all() -> void:
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	hunger_changed.emit(hunger, max_hunger)

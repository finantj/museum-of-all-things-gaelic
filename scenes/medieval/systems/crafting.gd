extends Node
## Crafting system - recipes for tools, weapons, armor, food, and buildings.
## Requires workstations (workbench, forge, fire pit) for advanced recipes.

signal item_crafted(item_id: String)
signal craft_failed(reason: String)

enum Station { NONE, WORKBENCH, FORGE, FIRE, LOOM }

# Crafting recipes
var recipes := {
	# Basic tools (no station needed)
	"stone_axe": {
		"ingredients": {"wood": 5, "stone": 4},
		"station": Station.NONE,
		"count": 1,
		"description": "A basic stone axe for felling trees."
	},
	"stone_pickaxe": {
		"ingredients": {"wood": 5, "stone": 6},
		"station": Station.NONE,
		"count": 1,
		"description": "A stone pickaxe for mining."
	},
	"club": {
		"ingredients": {"wood": 6},
		"station": Station.NONE,
		"count": 1,
		"description": "A crude wooden club."
	},
	"hammer": {
		"ingredients": {"wood": 3, "stone": 2},
		"station": Station.NONE,
		"count": 1,
		"description": "A hammer for building."
	},

	# Fire pit recipes
	"cooked_meat": {
		"ingredients": {"deer_meat": 1},
		"station": Station.FIRE,
		"count": 1,
		"description": "Roasted venison."
	},
	"cooked_fish": {
		"ingredients": {"fish": 1},
		"station": Station.FIRE,
		"count": 1,
		"description": "Grilled fish."
	},
	"bread": {
		"ingredients": {"flax": 4},
		"station": Station.FIRE,
		"count": 2,
		"description": "Simple flatbread."
	},

	# Workbench recipes
	"wooden_shield": {
		"ingredients": {"wood": 10, "leather": 4, "resin": 2},
		"station": Station.WORKBENCH,
		"count": 1,
		"description": "A round wooden shield."
	},
	"spear": {
		"ingredients": {"wood": 5, "flint": 3},
		"station": Station.WORKBENCH,
		"count": 1,
		"description": "A flint-tipped spear."
	},
	"bow": {
		"ingredients": {"wood": 8, "leather": 2},
		"station": Station.WORKBENCH,
		"count": 1,
		"description": "A simple hunting bow."
	},
	"arrow": {
		"ingredients": {"wood": 2, "feather": 1, "flint": 1},
		"station": Station.WORKBENCH,
		"count": 10,
		"description": "Flint-tipped arrows."
	},
	"fishing_rod": {
		"ingredients": {"wood": 4, "leather": 2},
		"station": Station.WORKBENCH,
		"count": 1,
		"description": "For fishing in Lough Key."
	},
	"leather_helm": {
		"ingredients": {"leather": 6},
		"station": Station.WORKBENCH,
		"count": 1,
		"description": "A hardened leather cap."
	},
	"leather_chest": {
		"ingredients": {"leather": 10, "bone": 4},
		"station": Station.WORKBENCH,
		"count": 1,
		"description": "Leather armor with bone reinforcement."
	},
	"wool_cape": {
		"ingredients": {"wool": 8},
		"station": Station.WORKBENCH,
		"count": 1,
		"description": "A warm woolen brat (cloak)."
	},

	# Forge recipes
	"bronze_axe": {
		"ingredients": {"bronze": 8, "wood": 4},
		"station": Station.FORGE,
		"count": 1,
		"description": "A bronze-headed axe."
	},
	"bronze_sword": {
		"ingredients": {"bronze": 12, "wood": 4, "leather": 2},
		"station": Station.FORGE,
		"count": 1,
		"description": "A bronze sword in the Irish style."
	},
	"iron_axe": {
		"ingredients": {"iron": 10, "wood": 4},
		"station": Station.FORGE,
		"count": 1,
		"description": "A sturdy iron axe."
	},
	"iron_sword": {
		"ingredients": {"iron": 15, "wood": 4, "leather": 3},
		"station": Station.FORGE,
		"count": 1,
		"description": "A fine iron sword."
	},

	# Building pieces (workbench)
	"wattle_wall": {
		"ingredients": {"wood": 4},
		"station": Station.WORKBENCH,
		"count": 2,
		"description": "Wattle wall section."
	},
	"thatch_roof": {
		"ingredients": {"thatch": 4, "wood": 2},
		"station": Station.WORKBENCH,
		"count": 2,
		"description": "Thatched roof section."
	},
	"wooden_floor": {
		"ingredients": {"wood": 6},
		"station": Station.WORKBENCH,
		"count": 2,
		"description": "Wooden floor section."
	},
	"wooden_door": {
		"ingredients": {"wood": 8},
		"station": Station.WORKBENCH,
		"count": 1,
		"description": "A wooden door."
	},

	# Stations
	"fire_pit": {
		"ingredients": {"stone": 5, "wood": 2},
		"station": Station.NONE,
		"count": 1,
		"description": "A stone fire pit for cooking."
	},
	"workbench": {
		"ingredients": {"wood": 10},
		"station": Station.NONE,
		"count": 1,
		"description": "A workbench for crafting."
	},
	"forge": {
		"ingredients": {"stone": 20, "wood": 5, "clay": 10},
		"station": Station.WORKBENCH,
		"count": 1,
		"description": "A forge for metalworking."
	},
	"bed": {
		"ingredients": {"wood": 8, "wool": 4, "leather": 2},
		"station": Station.WORKBENCH,
		"count": 1,
		"description": "A bed for resting and setting spawn."
	},

	# Special
	"mead": {
		"ingredients": {"honey": 3},
		"station": Station.FIRE,
		"count": 1,
		"description": "A potent drink of fermented honey."
	},
}

func can_craft(recipe_id: String, inventory: Node, nearby_station: Station) -> bool:
	if recipe_id not in recipes:
		return false

	var recipe := recipes[recipe_id]

	# Check station requirement
	if recipe.station != Station.NONE and recipe.station != nearby_station:
		return false

	# Check ingredients
	for ingredient_id in recipe.ingredients:
		var needed: int = recipe.ingredients[ingredient_id]
		if not inventory.has_item(ingredient_id, needed):
			return false

	return true

func craft(recipe_id: String, inventory: Node, nearby_station: Station) -> bool:
	if not can_craft(recipe_id, inventory, nearby_station):
		var recipe = recipes.get(recipe_id)
		if recipe and recipe.station != Station.NONE and recipe.station != nearby_station:
			craft_failed.emit("Need a %s to craft this." % _station_name(recipe.station))
		else:
			craft_failed.emit("Missing ingredients.")
		return false

	var recipe := recipes[recipe_id]

	# Consume ingredients
	for ingredient_id in recipe.ingredients:
		inventory.remove_item(ingredient_id, recipe.ingredients[ingredient_id])

	# Add crafted item
	var success := inventory.add_item(recipe_id, recipe.count)
	if success:
		item_crafted.emit(recipe_id)
	else:
		craft_failed.emit("Inventory full.")
		# Refund ingredients
		for ingredient_id in recipe.ingredients:
			inventory.add_item(ingredient_id, recipe.ingredients[ingredient_id])

	return success

func get_available_recipes(inventory: Node, nearby_station: Station) -> Array[String]:
	var available: Array[String] = []
	for recipe_id in recipes:
		if can_craft(recipe_id, inventory, nearby_station):
			available.append(recipe_id)
	return available

func get_all_recipes() -> Dictionary:
	return recipes

func _station_name(station: Station) -> String:
	match station:
		Station.WORKBENCH: return "workbench"
		Station.FORGE: return "forge"
		Station.FIRE: return "fire pit"
		Station.LOOM: return "loom"
		_: return "none"

extends Node
## Inventory system - item storage, weight management, and equipment slots.

signal item_added(item: Dictionary)
signal item_removed(item_name: String, count: int)
signal inventory_changed()
signal weight_changed(current: float, maximum: float)
signal equipped_changed(slot: String, item: Dictionary)

const MAX_SLOTS := 32
const BASE_CARRY_WEIGHT := 300.0

var items: Array[Dictionary] = []
var max_weight := BASE_CARRY_WEIGHT
var current_weight := 0.0

# Equipment slots
var equipped := {
	"head": {},
	"chest": {},
	"legs": {},
	"cape": {},
	"weapon": {},
	"shield": {},
	"tool": {},
}

# Item database - items available in 13th century Roscommon
var item_db := {
	# Resources
	"wood": {"name": "Adhmad", "name_en": "Wood", "weight": 2.0, "stack": 50, "type": "resource"},
	"stone": {"name": "Cloch", "name_en": "Stone", "weight": 3.0, "stack": 50, "type": "resource"},
	"flint": {"name": "Breochloch", "name_en": "Flint", "weight": 0.5, "stack": 20, "type": "resource"},
	"leather": {"name": "Leathar", "name_en": "Leather", "weight": 1.0, "stack": 20, "type": "resource"},
	"iron": {"name": "Iarann", "name_en": "Iron Ore", "weight": 4.0, "stack": 30, "type": "resource"},
	"bronze": {"name": "Cre-umha", "name_en": "Bronze", "weight": 3.5, "stack": 30, "type": "resource"},
	"wool": {"name": "Olann", "name_en": "Wool", "weight": 0.5, "stack": 30, "type": "resource"},
	"flax": {"name": "Lion", "name_en": "Flax", "weight": 0.3, "stack": 30, "type": "resource"},
	"thatch": {"name": "Tuí", "name_en": "Thatch", "weight": 1.0, "stack": 50, "type": "resource"},
	"clay": {"name": "Cré", "name_en": "Clay", "weight": 2.0, "stack": 30, "type": "resource"},
	"bone": {"name": "Cnámh", "name_en": "Bone", "weight": 1.0, "stack": 20, "type": "resource"},
	"feather": {"name": "Cleite", "name_en": "Feather", "weight": 0.1, "stack": 50, "type": "resource"},
	"resin": {"name": "Roisín", "name_en": "Resin", "weight": 0.5, "stack": 20, "type": "resource"},

	# Food (raw)
	"deer_meat": {"name": "Feoil Fia", "name_en": "Venison", "weight": 1.5, "stack": 20, "type": "food_raw",
		"health_bonus": 15.0, "stamina_bonus": 10.0, "hunger_restore": 25.0, "duration": 300.0},
	"fish": {"name": "Iasc", "name_en": "Fish", "weight": 1.0, "stack": 20, "type": "food_raw",
		"health_bonus": 10.0, "stamina_bonus": 15.0, "hunger_restore": 20.0, "duration": 240.0},
	"berries": {"name": "Sméara", "name_en": "Berries", "weight": 0.2, "stack": 50, "type": "food",
		"health_bonus": 5.0, "stamina_bonus": 10.0, "hunger_restore": 10.0, "duration": 180.0},
	"mushroom": {"name": "Beacán", "name_en": "Mushroom", "weight": 0.2, "stack": 50, "type": "food",
		"health_bonus": 8.0, "stamina_bonus": 5.0, "hunger_restore": 8.0, "duration": 150.0},
	"honey": {"name": "Mil", "name_en": "Honey", "weight": 0.5, "stack": 10, "type": "food",
		"health_bonus": 12.0, "stamina_bonus": 15.0, "hunger_restore": 15.0, "duration": 300.0},
	"bread": {"name": "Arán", "name_en": "Bread", "weight": 0.5, "stack": 20, "type": "food",
		"health_bonus": 15.0, "stamina_bonus": 20.0, "hunger_restore": 30.0, "duration": 360.0},
	"cooked_meat": {"name": "Feoil Bruite", "name_en": "Cooked Meat", "weight": 1.0, "stack": 20, "type": "food",
		"health_bonus": 25.0, "stamina_bonus": 15.0, "hunger_restore": 35.0, "duration": 480.0},
	"cooked_fish": {"name": "Iasc Bruite", "name_en": "Cooked Fish", "weight": 0.8, "stack": 20, "type": "food",
		"health_bonus": 20.0, "stamina_bonus": 25.0, "hunger_restore": 30.0, "duration": 420.0},
	"mead": {"name": "Miodh", "name_en": "Mead", "weight": 1.0, "stack": 10, "type": "food",
		"health_bonus": 20.0, "stamina_bonus": 30.0, "hunger_restore": 10.0, "duration": 600.0},

	# Tools
	"stone_axe": {"name": "Tua Chloiche", "name_en": "Stone Axe", "weight": 3.0, "stack": 1, "type": "tool",
		"tool_type": "axe", "damage": 8.0, "durability": 100.0},
	"bronze_axe": {"name": "Tua Chré-umha", "name_en": "Bronze Axe", "weight": 3.5, "stack": 1, "type": "tool",
		"tool_type": "axe", "damage": 15.0, "durability": 200.0},
	"iron_axe": {"name": "Tua Iarainn", "name_en": "Iron Axe", "weight": 4.0, "stack": 1, "type": "tool",
		"tool_type": "axe", "damage": 25.0, "durability": 400.0},
	"stone_pickaxe": {"name": "Piocóid Chloiche", "name_en": "Stone Pickaxe", "weight": 3.0, "stack": 1, "type": "tool",
		"tool_type": "pickaxe", "damage": 8.0, "durability": 100.0},
	"fishing_rod": {"name": "Slat Iascaireachta", "name_en": "Fishing Rod", "weight": 1.5, "stack": 1, "type": "tool",
		"tool_type": "fishing", "durability": 150.0},
	"hammer": {"name": "Casúr", "name_en": "Hammer", "weight": 2.5, "stack": 1, "type": "tool",
		"tool_type": "hammer", "durability": 200.0},

	# Weapons
	"club": {"name": "Smiste", "name_en": "Club", "weight": 2.0, "stack": 1, "type": "weapon",
		"damage": 10.0, "durability": 80.0, "weapon_type": "blunt"},
	"bronze_sword": {"name": "Claidheamh Cré-umha", "name_en": "Bronze Sword", "weight": 3.0, "stack": 1, "type": "weapon",
		"damage": 20.0, "durability": 200.0, "weapon_type": "slash"},
	"iron_sword": {"name": "Claidheamh Iarainn", "name_en": "Iron Sword", "weight": 3.5, "stack": 1, "type": "weapon",
		"damage": 35.0, "durability": 400.0, "weapon_type": "slash"},
	"spear": {"name": "Sleagh", "name_en": "Spear", "weight": 2.5, "stack": 1, "type": "weapon",
		"damage": 25.0, "durability": 250.0, "weapon_type": "pierce"},
	"bow": {"name": "Bogha", "name_en": "Bow", "weight": 2.0, "stack": 1, "type": "weapon",
		"damage": 15.0, "durability": 200.0, "weapon_type": "ranged"},
	"arrow": {"name": "Saighead", "name_en": "Arrow", "weight": 0.1, "stack": 100, "type": "ammo"},
	"wooden_shield": {"name": "Sciath Adhmaid", "name_en": "Wooden Shield", "weight": 4.0, "stack": 1, "type": "shield",
		"block": 20.0, "durability": 150.0},

	# Armor
	"leather_helm": {"name": "Clogad Leathair", "name_en": "Leather Helm", "weight": 1.5, "stack": 1, "type": "armor",
		"slot": "head", "armor": 5.0, "durability": 100.0},
	"leather_chest": {"name": "Luíreach Leathair", "name_en": "Leather Armor", "weight": 5.0, "stack": 1, "type": "armor",
		"slot": "chest", "armor": 10.0, "durability": 150.0},
	"wool_cape": {"name": "Brat Olna", "name_en": "Wool Cape", "weight": 1.0, "stack": 1, "type": "armor",
		"slot": "cape", "armor": 2.0, "durability": 100.0},

	# Building
	"wattle_wall": {"name": "Balla Caolach", "name_en": "Wattle Wall", "weight": 5.0, "stack": 10, "type": "building"},
	"thatch_roof": {"name": "Díon Tuí", "name_en": "Thatch Roof", "weight": 3.0, "stack": 10, "type": "building"},
	"wooden_floor": {"name": "Urlár Adhmaid", "name_en": "Wooden Floor", "weight": 4.0, "stack": 10, "type": "building"},
	"wooden_door": {"name": "Doras Adhmaid", "name_en": "Wooden Door", "weight": 6.0, "stack": 5, "type": "building"},
	"fire_pit": {"name": "Tine", "name_en": "Fire Pit", "weight": 8.0, "stack": 1, "type": "building"},
	"workbench": {"name": "Binse Oibre", "name_en": "Workbench", "weight": 10.0, "stack": 1, "type": "building"},
	"forge": {"name": "Ceárta", "name_en": "Forge", "weight": 20.0, "stack": 1, "type": "building"},
	"bed": {"name": "Leaba", "name_en": "Bed", "weight": 8.0, "stack": 1, "type": "building"},
}

func add_item(item_id: String, count: int = 1) -> bool:
	if item_id not in item_db:
		return false

	var template := item_db[item_id]
	var added_weight := template.weight * count

	if current_weight + added_weight > max_weight:
		return false # Too heavy

	# Try to stack with existing
	for i in range(items.size()):
		if items[i].id == item_id and items[i].count < template.stack:
			var space := template.stack - items[i].count
			var to_add := mini(count, space)
			items[i].count += to_add
			count -= to_add
			if count <= 0:
				break

	# Add new stacks for remaining
	while count > 0 and items.size() < MAX_SLOTS:
		var stack_size := mini(count, template.stack)
		var item := template.duplicate()
		item.id = item_id
		item.count = stack_size
		items.append(item)
		count -= stack_size

	_recalculate_weight()
	inventory_changed.emit()
	item_added.emit(template)
	return count <= 0

func remove_item(item_id: String, count: int = 1) -> bool:
	var remaining := count
	var indices_to_remove: Array[int] = []

	for i in range(items.size() - 1, -1, -1):
		if items[i].id == item_id:
			if items[i].count <= remaining:
				remaining -= items[i].count
				indices_to_remove.append(i)
			else:
				items[i].count -= remaining
				remaining = 0

			if remaining <= 0:
				break

	if remaining > 0:
		return false # Not enough items

	for idx in indices_to_remove:
		items.remove_at(idx)

	_recalculate_weight()
	inventory_changed.emit()
	item_removed.emit(item_id, count)
	return true

func has_item(item_id: String, count: int = 1) -> bool:
	var total := 0
	for item in items:
		if item.id == item_id:
			total += item.count
	return total >= count

func get_item_count(item_id: String) -> int:
	var total := 0
	for item in items:
		if item.id == item_id:
			total += item.count
	return total

func equip_item(item_id: String) -> bool:
	if not has_item(item_id):
		return false

	var template := item_db[item_id]
	var slot := ""

	match template.type:
		"weapon":
			slot = "weapon"
		"shield":
			slot = "shield"
		"tool":
			slot = "tool"
		"armor":
			slot = template.get("slot", "")

	if slot.is_empty():
		return false

	# Unequip current
	if not equipped[slot].is_empty():
		add_item(equipped[slot].id)

	equipped[slot] = template.duplicate()
	equipped[slot].id = item_id
	remove_item(item_id)

	equipped_changed.emit(slot, equipped[slot])
	return true

func _recalculate_weight() -> void:
	current_weight = 0.0
	for item in items:
		current_weight += item.weight * item.count
	weight_changed.emit(current_weight, max_weight)

func get_items_of_type(type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in items:
		if item.type == type:
			result.append(item)
	return result

func get_all_item_definitions() -> Dictionary:
	return item_db

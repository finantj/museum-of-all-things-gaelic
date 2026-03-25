extends Node3D
## Spawns NPCs around the world - MacDermot clan, monks, villagers, merchants.

var rng := RandomNumberGenerator.new()

# NPC data for the MacDermot lordship of Moylurg
var npc_definitions := {
	"macdermot_lord": {
		"name": "Cormac MacDermot",
		"title": "Rí Mhaigh Luirg", # King of Moylurg
		"location": Vector3(95.0, 4.0, 105.0), # Castle Island
		"dialogue": [
			"Fáilte go Loch Cé! Welcome to Lough Key, traveler.",
			"I am Cormac MacDermot, lord of Moylurg. These lands have been ours since time beyond memory.",
			"The rock upon which we stand has been the seat of the MacDermots for generations.",
			"Serve me well, and you shall have land and cattle. Betray me, and the lake shall be your grave.",
			"The monks on Trinity Island keep the old knowledge. Visit them if you seek wisdom.",
			"Beware the wolves in the deep forest. They grow bold in winter."
		],
		"type": "noble"
	},
	"macdermot_wife": {
		"name": "Gráinne Ní Chonchobhair",
		"title": "Lady of Moylurg",
		"location": Vector3(93.0, 4.0, 106.0),
		"dialogue": [
			"You are welcome in our hall, stranger.",
			"The MacDermots have ruled from this rock since the time of Maelruanaidh.",
			"If you would eat, speak with the cook. We do not let guests go hungry.",
			"My husband's holdings stretch from Lough Key to the Curlew Mountains."
		],
		"type": "noble"
	},
	"brehon": {
		"name": "Flann mac Lonáin",
		"title": "Breitheamh", # Brehon judge
		"location": Vector3(92.0, 4.0, 104.0),
		"dialogue": [
			"I am the Brehon of Moylurg. I keep the law of the Féineachas.",
			"Under Brehon law, every person has an honour price. Even the king must pay his debts.",
			"If you have a dispute, bring it before me. Justice will be done.",
			"The law is older than any king. It binds us all."
		],
		"type": "scholar"
	},
	"monk_abbot": {
		"name": "Brother Colmán",
		"title": "Ab Inis na Tríonóide", # Abbot of Trinity Island
		"location": Vector3(88.0, 3.0, 92.0),
		"dialogue": [
			"Dia dhuit, child. God be with you.",
			"We are the Premonstratensian order. We tend this abbey and preserve the written word.",
			"The Annals record all that passes in these lands. History must not be forgotten.",
			"Come, pray with us. The chapel bell rings at dawn and dusk.",
			"We keep a garden of herbs for healing. If you are injured, we may help."
		],
		"type": "monk"
	},
	"monk_scribe": {
		"name": "Brother Malachy",
		"title": "Scríbhneoir", # Scribe
		"location": Vector3(89.0, 3.0, 93.0),
		"dialogue": [
			"I copy the manuscripts so that knowledge may endure.",
			"The Annals of Loch Cé record the deeds of kings and the sorrows of the people.",
			"In this year of our Lord, much has happened that must be written.",
			"Ink and vellum are precious. Each page is a treasure."
		],
		"type": "monk"
	},
	"blacksmith": {
		"name": "Gobnait",
		"title": "Gabha", # Smith
		"location": Vector3(142.0, 3.0, 101.0),
		"dialogue": [
			"Need something forged? Bring me iron and I'll make it sing.",
			"A good sword needs good iron. The bogs yield the best ore.",
			"The MacDermot's warriors keep me busy. There's always need for blades.",
			"Bronze was the old way. Iron is the future."
		],
		"type": "craftsman"
	},
	"merchant": {
		"name": "Tadhg the Trader",
		"title": "Ceannaí", # Merchant
		"location": Vector3(138.0, 3.0, 98.0),
		"dialogue": [
			"Finest goods from Connacht and beyond! Come, look!",
			"I trade up and down the Shannon. Lough Key is a fine stopping place.",
			"Wool, leather, bronze - I deal in all manner of goods.",
			"The MacDermots keep the roads safe. Good for trade, that."
		],
		"type": "merchant"
	},
	"fisherman": {
		"name": "Séamus",
		"title": "Iascaire", # Fisherman
		"location": Vector3(115.0, 0.5, 120.0),
		"dialogue": [
			"The lake is generous if you know where to cast your line.",
			"Pike and trout, mostly. Sometimes an eel if you're patient.",
			"See that island? The MacDermot himself lives there. Nobody crosses without his leave.",
			"The currach is the best boat for these waters. Light and fast."
		],
		"type": "commoner"
	},
	"farmer": {
		"name": "Pádraig",
		"title": "Feirmeoir", # Farmer
		"location": Vector3(155.0, 5.0, 125.0),
		"dialogue": [
			"Oats and barley are what we grow. The land is good here.",
			"The cattle are the real wealth. A man's honor is measured in cows.",
			"We pay our dues to the MacDermot. In return, he protects us.",
			"Hard work and honest sweat - that's the life of a túath."
		],
		"type": "commoner"
	},
	"warrior": {
		"name": "Donncha mac Aodha",
		"title": "Gallóglaigh", # Gallowglass warrior
		"location": Vector3(97.0, 4.0, 108.0),
		"dialogue": [
			"I serve the MacDermot with my sword arm. That is my oath.",
			"These walls have never been taken. The rock is our fortress.",
			"The Connacht clans fight among themselves, but the MacDermots endure.",
			"If you can swing a blade, there's always work for a warrior."
		],
		"type": "warrior"
	},
}

func _ready() -> void:
	rng.seed = 1250
	call_deferred("_spawn_all_npcs")

func _spawn_all_npcs() -> void:
	for npc_id in npc_definitions:
		var data := npc_definitions[npc_id]
		_create_npc(npc_id, data)

	# Spawn some generic villagers
	var villager_positions := [
		Vector3(135.0, 3.0, 95.0), Vector3(145.0, 3.0, 105.0),
		Vector3(150.0, 4.0, 98.0), Vector3(138.0, 3.0, 108.0),
		Vector3(143.0, 3.5, 95.0), Vector3(148.0, 4.0, 102.0),
	]
	for i in range(villager_positions.size()):
		var names := ["Niamh", "Ciarán", "Aoife", "Ruairí", "Siobhán", "Cathal"]
		_create_npc("villager_%d" % i, {
			"name": names[i],
			"title": "Tuathánach", # Commoner
			"location": villager_positions[i],
			"dialogue": [
				"Dia dhuit! A fine day, is it not?",
				"The MacDermot keeps us safe.",
				"Have you seen the monastery on the island? Beautiful place.",
			],
			"type": "commoner"
		})

func _create_npc(id: String, data: Dictionary) -> void:
	var npc := CharacterBody3D.new()
	npc.name = "NPC_%s" % id

	# Collision
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.8
	col.shape = shape
	col.position.y = 0.9
	npc.add_child(col)

	# Visual model
	var model := Node3D.new()
	model.name = "Model"

	# Body
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.25
	capsule.height = 1.4
	body.mesh = capsule
	body.position.y = 0.7

	var body_color := _get_npc_color(data.type)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.8
	body.material_override = mat
	model.add_child(body)

	# Head
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	head.mesh = sphere
	head.position.y = 1.55
	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.75, 0.6, 0.5)
	head.material_override = skin_mat
	model.add_child(head)

	npc.add_child(model)

	# Interaction area
	var interact_body := StaticBody3D.new()
	interact_body.collision_layer = 4 # Pickable
	interact_body.collision_mask = 0
	interact_body.set_meta("npc_id", id)
	interact_body.set_meta("npc_name", data.name)
	interact_body.set_meta("npc_title", data.title)
	interact_body.set_meta("npc_dialogue", data.dialogue)
	interact_body.set_script(preload("res://scenes/medieval/npcs/npc_interactable.gd"))

	var interact_col := CollisionShape3D.new()
	var interact_shape := CapsuleShape3D.new()
	interact_shape.radius = 0.35
	interact_shape.height = 1.8
	interact_col.shape = interact_shape
	interact_col.position.y = 0.9
	interact_body.add_child(interact_col)
	npc.add_child(interact_body)

	# Name label (3D)
	var label := Label3D.new()
	label.text = "%s\n%s" % [data.name, data.title]
	label.font_size = 14
	label.position.y = 2.1
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(1, 1, 1, 0.8)
	npc.add_child(label)

	npc.position = data.location
	npc.rotation.y = rng.randf() * TAU

	add_child(npc)

func _get_npc_color(type: String) -> Color:
	match type:
		"noble":
			return Color(0.5, 0.15, 0.15) # Red/crimson - noble colors
		"monk":
			return Color(0.8, 0.75, 0.65) # White/cream robes
		"warrior":
			return Color(0.35, 0.3, 0.25) # Dark armor
		"craftsman":
			return Color(0.45, 0.35, 0.2) # Leather apron
		"merchant":
			return Color(0.4, 0.35, 0.5) # Dyed cloth
		_:
			return Color(0.5, 0.45, 0.35) # Plain undyed wool

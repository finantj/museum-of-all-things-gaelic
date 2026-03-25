extends StaticBody3D
## Makes an NPC interactable - shows dialogue when player presses interact.

var dialogue_index := 0

func interact(player: CharacterBody3D) -> void:
	var npc_name: String = get_meta("npc_name", "Stranger")
	var npc_title: String = get_meta("npc_title", "")
	var dialogue: Array = get_meta("npc_dialogue", ["..."])

	if dialogue_index >= dialogue.size():
		dialogue_index = 0

	var line: String = dialogue[dialogue_index]
	dialogue_index += 1

	# Find the HUD and show dialogue
	var hud = player.get_parent().get_node_or_null("HUD")
	if hud and hud.has_method("show_dialogue"):
		hud.show_dialogue(npc_name, npc_title, line)
	else:
		print("[%s - %s]: %s" % [npc_name, npc_title, line])

	# Face the player
	var dir := player.global_position - global_position
	dir.y = 0
	if dir.length() > 0.1:
		get_parent().look_at(player.global_position, Vector3.UP)
		get_parent().rotation.y += PI

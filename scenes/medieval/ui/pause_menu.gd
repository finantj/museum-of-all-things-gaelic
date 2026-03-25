extends Control
## Pause menu for the medieval game.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_menu()

func _build_menu() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Dark overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	add_child(overlay)

	# Center panel
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(300, 350)
	panel.position = Vector2(-150, -175)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.06, 0.95)
	style.border_color = Color(0.5, 0.4, 0.25)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# Title
	var title := Label.new()
	title.text = "Loch Cé"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Moylurg, Anno Domini 1250"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	vbox.add_child(subtitle)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Buttons
	var resume_btn := _create_button("Resume")
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)

	var settings_btn := _create_button("Settings")
	vbox.add_child(settings_btn)

	var quit_btn := _create_button("Return to Museum")
	quit_btn.pressed.connect(_on_quit)
	vbox.add_child(quit_btn)

	panel.add_child(vbox)
	add_child(panel)

func _create_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 40)
	btn.add_theme_font_size_override("font_size", 16)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.08)
	style.border_color = Color(0.5, 0.4, 0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.25, 0.2, 0.12)
	hover.border_color = Color(0.7, 0.55, 0.3)
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(3)
	hover.set_content_margin_all(8)
	btn.add_theme_stylebox_override("hover", hover)

	return btn

func _on_resume() -> void:
	# Signal parent to unpause
	var game := get_tree().root.get_node_or_null("MedievalGame")
	if game and game.has_method("_toggle_pause"):
		game._toggle_pause()

func _on_quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

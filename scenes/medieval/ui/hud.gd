extends CanvasLayer
## In-game HUD showing health, stamina, hunger bars, minimap, and interaction prompts.

var health_bar: ProgressBar
var stamina_bar: ProgressBar
var hunger_bar: ProgressBar
var interaction_label: Label
var dialogue_panel: PanelContainer
var dialogue_name: Label
var dialogue_text: Label
var crosshair: TextureRect
var day_time_label: Label
var notification_label: Label
var notification_timer := 0.0

# Crafting menu
var crafting_panel: Control
var inventory_panel: Control

func _ready() -> void:
	layer = 5
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- Health / Stamina / Hunger bars (bottom-center, Valheim style) ---
	var bars_container := VBoxContainer.new()
	bars_container.name = "BarsContainer"
	bars_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bars_container.position = Vector2(-150, -80)
	bars_container.custom_minimum_size = Vector2(300, 0)
	bars_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bars_container)

	# Health
	var health_row := _create_bar_row("Health", Color(0.8, 0.15, 0.15))
	health_bar = health_row.get_node("Bar")
	bars_container.add_child(health_row)

	# Stamina
	var stamina_row := _create_bar_row("Stamina", Color(0.85, 0.75, 0.2))
	stamina_bar = stamina_row.get_node("Bar")
	bars_container.add_child(stamina_row)

	# Hunger
	var hunger_row := _create_bar_row("Hunger", Color(0.6, 0.4, 0.15))
	hunger_bar = hunger_row.get_node("Bar")
	bars_container.add_child(hunger_row)

	# --- Crosshair (center) ---
	crosshair = TextureRect.new()
	crosshair.name = "Crosshair"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -8)
	crosshair.custom_minimum_size = Vector2(16, 16)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Draw a simple crosshair
	var crosshair_label := Label.new()
	crosshair_label.text = "+"
	crosshair_label.add_theme_font_size_override("font_size", 24)
	crosshair_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	crosshair_label.position = Vector2(-6, -14)
	crosshair.add_child(crosshair_label)
	root.add_child(crosshair)

	# --- Interaction prompt (bottom-center, above bars) ---
	interaction_label = Label.new()
	interaction_label.name = "InteractionPrompt"
	interaction_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	interaction_label.position = Vector2(-100, -120)
	interaction_label.custom_minimum_size = Vector2(200, 30)
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.add_theme_font_size_override("font_size", 16)
	interaction_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	interaction_label.text = ""
	interaction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(interaction_label)

	# --- Dialogue panel (center) ---
	dialogue_panel = PanelContainer.new()
	dialogue_panel.name = "DialoguePanel"
	dialogue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_panel.position = Vector2(-250, -200)
	dialogue_panel.custom_minimum_size = Vector2(500, 80)
	dialogue_panel.visible = false
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.85)
	style.border_color = Color(0.6, 0.5, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	dialogue_panel.add_theme_stylebox_override("panel", style)

	var dialogue_vbox := VBoxContainer.new()

	dialogue_name = Label.new()
	dialogue_name.add_theme_font_size_override("font_size", 18)
	dialogue_name.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	dialogue_vbox.add_child(dialogue_name)

	dialogue_text = Label.new()
	dialogue_text.add_theme_font_size_override("font_size", 14)
	dialogue_text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_vbox.add_child(dialogue_text)

	dialogue_panel.add_child(dialogue_vbox)
	root.add_child(dialogue_panel)

	# --- Day/time indicator (top-right) ---
	day_time_label = Label.new()
	day_time_label.name = "DayTime"
	day_time_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	day_time_label.position = Vector2(-200, 10)
	day_time_label.custom_minimum_size = Vector2(190, 30)
	day_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	day_time_label.add_theme_font_size_override("font_size", 14)
	day_time_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.7, 0.7))
	day_time_label.text = "Moylurg - Dawn"
	day_time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(day_time_label)

	# --- Notification label (top-center) ---
	notification_label = Label.new()
	notification_label.name = "Notification"
	notification_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notification_label.position = Vector2(-200, 40)
	notification_label.custom_minimum_size = Vector2(400, 30)
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.add_theme_font_size_override("font_size", 18)
	notification_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	notification_label.text = ""
	notification_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(notification_label)

	# --- Controls hint (bottom-left) ---
	var controls := Label.new()
	controls.name = "ControlsHint"
	controls.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	controls.position = Vector2(10, -120)
	controls.add_theme_font_size_override("font_size", 11)
	controls.add_theme_color_override("font_color", Color(0.7, 0.7, 0.65, 0.5))
	controls.text = "WASD - Move | Mouse - Look | Shift - Sprint\nE - Interact | LMB - Attack | RMB - Block\nSpace - Jump | Esc - Pause"
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(controls)

func _create_bar_row(label_text: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(70, 0)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.75))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.custom_minimum_size = Vector2(220, 16)
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Style the bar
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.1, 0.7)
	bg.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)

	row.add_child(bar)
	return row

func _process(delta: float) -> void:
	if notification_timer > 0:
		notification_timer -= delta
		if notification_timer <= 0:
			notification_label.text = ""

	# Auto-hide dialogue
	if dialogue_panel.visible:
		pass # Stays until next interact or timeout

func _on_health_changed(current: float, maximum: float) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current

func _on_stamina_changed(current: float, maximum: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = maximum
		stamina_bar.value = current

func _on_hunger_changed(current: float, maximum: float) -> void:
	if hunger_bar:
		hunger_bar.max_value = maximum
		hunger_bar.value = current

func show_dialogue(npc_name: String, npc_title: String, text: String) -> void:
	dialogue_name.text = "%s - %s" % [npc_name, npc_title]
	dialogue_text.text = text
	dialogue_panel.visible = true

	# Auto-hide after 5 seconds
	get_tree().create_timer(5.0).timeout.connect(func():
		dialogue_panel.visible = false
	, CONNECT_ONE_SHOT)

func show_notification(text: String, duration: float = 3.0) -> void:
	notification_label.text = text
	notification_timer = duration

func show_interaction_prompt(text: String) -> void:
	interaction_label.text = text

func hide_interaction_prompt() -> void:
	interaction_label.text = ""

func update_time_display(hour: float, period: String) -> void:
	var hour_int := int(hour)
	var minute := int((hour - hour_int) * 60)
	day_time_label.text = "Moylurg - %02d:%02d - %s" % [hour_int, minute, period.capitalize()]

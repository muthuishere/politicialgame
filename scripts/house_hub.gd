extends Control
##
## House Hub: the player's home. From here they step into the next scenario,
## review their journey, or — once eligible — face the ward election.
##

const TOP_BAR_H := 60

var stats_panel: PanelContainer
var main_col: VBoxContainer
var status_label: RichTextLabel
var primary_btn: Button
var secondary_btn: Button
var tertiary_btn: Button

func _ready() -> void:
	_build()
	_refresh_state()
	GameState.stat_changed.connect(func(_t, _s, _d, _v): _refresh_state())
	GameState.finances_changed.connect(func(_d, _v): _refresh_state())
	GameState.position_changed.connect(func(_p): _refresh_state())
	GameState.scenario_completed.connect(_on_scenario_completed)
	GameState.save_game()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG_PAGE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var strip := ColorRect.new()
	strip.color = Color(Palette.SAFFRON.r, Palette.SAFFRON.g, Palette.SAFFRON.b, 0.35)
	strip.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	strip.size.x = 12
	strip.offset_right = 12
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 32
	root.offset_top = 24
	root.offset_right = -32
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", Palette.SP_MD)
	add_child(root)

	root.add_child(_make_top_bar())

	# Body: stats panel on right, main content on left
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", Palette.SP_LG)
	root.add_child(body)

	var main_panel := UI.make_panel()
	main_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(main_panel)

	main_col = VBoxContainer.new()
	main_col.add_theme_constant_override("separation", Palette.SP_MD)
	main_panel.add_child(main_col)

	stats_panel = StatsPanel.new()
	body.add_child(stats_panel)

	# Main content
	var eyebrow := Label.new()
	eyebrow.text = "YOUR HOUSE · ARYAVARTA"
	eyebrow.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	eyebrow.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	main_col.add_child(eyebrow)

	var heading := Label.new()
	heading.text = "The morning paper is on the veranda."
	heading.add_theme_font_size_override("font_size", Palette.FONT_HEADING)
	heading.add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
	main_col.add_child(heading)

	main_col.add_child(UI.make_divider())

	status_label = UI.make_body_label("", Palette.FONT_SUBHEAD, Palette.TEXT_SECONDARY)
	status_label.add_theme_constant_override("line_separation", 6)
	main_col.add_child(status_label)

	main_col.add_child(UI.make_spacer(Palette.SP_LG))

	# Buttons
	primary_btn = UI.make_button("Step into the day", "accent")
	primary_btn.custom_minimum_size = Vector2(0, 56)
	primary_btn.pressed.connect(_on_primary)
	main_col.add_child(primary_btn)

	secondary_btn = UI.make_button("", "ghost")
	secondary_btn.custom_minimum_size = Vector2(0, 48)
	secondary_btn.pressed.connect(_on_secondary)
	main_col.add_child(secondary_btn)

	tertiary_btn = UI.make_button("Return to title", "ghost")
	tertiary_btn.custom_minimum_size = Vector2(0, 40)
	tertiary_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/title.tscn"))
	main_col.add_child(tertiary_btn)

func _make_top_bar() -> Control:
	var bar := UI.make_panel()
	bar.custom_minimum_size.y = TOP_BAR_H

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", Palette.SP_LG)
	bar.add_child(h)

	h.add_child(_top_chip("STATE", "Aryavarta"))
	h.add_child(_v_divider())
	h.add_child(_top_chip("POSITION", GameState.position_title()))
	h.add_child(_v_divider())
	h.add_child(_top_chip("WEEK", str(GameState.turn)))
	h.add_child(_v_divider())
	h.add_child(_top_chip("FUNDS", UI.format_rupees(GameState.finances)))
	h.add_child(_v_divider())
	h.add_child(_top_chip("REFORM", str(GameState.reform_progress) + "%"))

	# Right-align logo
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(spacer)

	var logo := Label.new()
	logo.text = "SALAMIA"
	logo.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	logo.add_theme_color_override("font_color", Palette.TERRACOTTA)
	h.add_child(logo)

	return bar

func _top_chip(label: String, value: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var l := Label.new()
	l.text = label
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	v.add_child(l)
	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", Palette.FONT_BODY)
	val.add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
	v.add_child(val)
	return v

func _v_divider() -> Control:
	var c := ColorRect.new()
	c.color = Palette.BORDER
	c.custom_minimum_size = Vector2(1, 32)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return c

func _refresh_state() -> void:
	# Refresh top bar
	if has_node("VBoxContainer/PanelContainer"):
		pass  # rebuilt below
	# Easier: rebuild top bar by replacing first child
	var root := get_child(2) as VBoxContainer
	if root and root.get_child_count() > 0:
		var old_bar := root.get_child(0)
		var new_bar := _make_top_bar()
		root.remove_child(old_bar)
		old_bar.queue_free()
		root.add_child(new_bar)
		root.move_child(new_bar, 0)

	# Phase-appropriate status text + button labels
	match GameState.position:
		"volunteer":
			_refresh_volunteer()
		"councillor":
			_refresh_councillor()
		_:
			_refresh_endgame()

func _refresh_volunteer() -> void:
	var remaining := ScenarioLoader.remaining_for_phase("volunteer")
	var trust := GameState.local_trust

	if trust >= 30:
		status_label.text = "[i]A flyer has been pasted on every lamp-post overnight: ward elections in three weeks. The AJM nominates by Friday. Independents must register by Monday.[/i]\n\nYou could continue volunteer work — there is no shortage of it — or you could declare for the councillor seat. The ward, at least, has begun to recognise your name."
		primary_btn.text = "Declare for the councillor election"
		secondary_btn.text = "Another week of volunteer work (%d scenarios remain)" % remaining
		secondary_btn.visible = remaining > 0
	elif remaining > 0:
		status_label.text = "[i]Work continues. The ward is not yet ready to hand you a ballot — but every conversation, every fight picked, brings them closer.[/i]\n\nLocal trust must reach about 30 before an election bid will be viable."
		primary_btn.text = "Step into the day"
		secondary_btn.visible = false
	else:
		status_label.text = "[i]You have done everything that can be done from outside the system. The ward knows you — but barely enough. An election is uphill, but the alternative is to stop here.[/i]"
		primary_btn.text = "Declare for the councillor election anyway"
		secondary_btn.visible = false

func _refresh_councillor() -> void:
	var remaining := ScenarioLoader.remaining_for_phase("councillor")
	if remaining == 0:
		_refresh_endgame()
		return
	status_label.text = "[i]The brass plate on your office door is new. The ledger waits on the desk. So do the petitioners.[/i]\n\n%d matters remain on your desk this term." % [remaining]
	primary_btn.text = "Take the next item from the desk"
	secondary_btn.visible = false

func _refresh_endgame() -> void:
	primary_btn.text = "See the end of this chapter"
	secondary_btn.visible = false
	status_label.text = "[i]The term draws to a close. The newspapers have written what they will write. Allies have been made and lost. The Local Revenue Empowerment Act still waits for its champion at the state and national level — but that is another chapter.[/i]"

func _on_primary() -> void:
	match GameState.position:
		"volunteer":
			if GameState.local_trust >= 30 or ScenarioLoader.remaining_for_phase("volunteer") == 0:
				get_tree().change_scene_to_file("res://scenes/election.tscn")
			else:
				_go_to_scenario("volunteer")
		"councillor":
			if ScenarioLoader.remaining_for_phase("councillor") == 0:
				get_tree().change_scene_to_file("res://scenes/ending.tscn")
			else:
				_go_to_scenario("councillor")
		_:
			get_tree().change_scene_to_file("res://scenes/ending.tscn")

func _on_secondary() -> void:
	if GameState.position == "volunteer":
		_go_to_scenario("volunteer")

func _go_to_scenario(phase: String) -> void:
	var s = ScenarioLoader.pick_next_for_phase(phase)
	if s == null:
		# Fallback — shouldn't happen if button state is right
		_refresh_state()
		return
	get_tree().set_meta("pending_scenario", s)
	get_tree().change_scene_to_file("res://scenes/scenario.tscn")

func _on_scenario_completed(_id: String) -> void:
	GameState.advance_turn()
	GameState.save_game()

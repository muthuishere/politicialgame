extends Control

const OPENING := "[i]Your grandmother left you this house.[/i]\n\nNot money, not power — just a house, in a neighbourhood where the roads are broken and the garbage piles up on the corner of Tilak Road and Old Bazaar Lane.\n\nThe day you move in, a neighbour knocks. The tap has been leaking for two weeks. The municipality won't answer. You have no official position. But you have something they don't — time. And maybe, just maybe, a strange belief that politics can be different.\n\n[i]Welcome to Salamia.[/i]"

func _ready() -> void:
	_build()

func _build() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Palette.BG_PAGE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)

	# Letter + cards together are taller than a typical browser viewport.
	# Wrap in a ScrollContainer so the canvas can scroll internally instead
	# of leaving the "Choose this start" buttons stranded off-screen.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	margin.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var col := VBoxContainer.new()
	col.custom_minimum_size.x = 720
	col.add_theme_constant_override("separation", Palette.SP_LG)
	center.add_child(col)

	# The letter
	var letter := UI.make_letter_panel()
	col.add_child(letter)

	var letter_col := VBoxContainer.new()
	letter_col.add_theme_constant_override("separation", Palette.SP_MD)
	letter.add_child(letter_col)

	var eyebrow := Label.new()
	eyebrow.text = "ARYAVARTA · LATE MONSOON"
	eyebrow.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	eyebrow.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	letter_col.add_child(eyebrow)

	var body := UI.make_body_label(OPENING, Palette.FONT_SUBHEAD, Palette.TEXT_PRIMARY)
	body.add_theme_constant_override("line_separation", 8)
	letter_col.add_child(body)

	col.add_child(UI.make_spacer(8))

	# Background prompt
	var prompt := UI.make_body_label(
		"[center][b]Before you begin —[/b]\nwhat circumstances did you inherit?[/center]",
		Palette.FONT_SUBHEAD, Palette.TEXT_PRIMARY
	)
	col.add_child(prompt)

	# Two background choices, side by side
	var bg_row := HBoxContainer.new()
	bg_row.add_theme_constant_override("separation", Palette.SP_MD)
	bg_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(bg_row)

	bg_row.add_child(_make_bg_card(
		"Modest means",
		"₹50,000",
		"You teach part-time. The house is paid for. Every cause you take up costs something you can't easily replace.",
		"modest"
	))
	bg_row.add_child(_make_bg_card(
		"From a wealthy family",
		"₹2,00,000",
		"Your father runs a transport business. You start with cushion — and with people who expect things in return.",
		"wealthy"
	))

func _make_bg_card(title: String, amount: String, blurb: String, key: String) -> Control:
	var panel := UI.make_panel()
	panel.custom_minimum_size = Vector2(320, 200)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Palette.SP_SM)
	panel.add_child(v)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", Palette.FONT_SUBHEAD)
	title_lbl.add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
	v.add_child(title_lbl)

	var amt := Label.new()
	amt.text = amount
	amt.add_theme_font_size_override("font_size", Palette.FONT_HEADING)
	amt.add_theme_color_override("font_color", Palette.TERRACOTTA)
	v.add_child(amt)

	v.add_child(UI.make_divider())

	var body := UI.make_body_label(blurb, Palette.FONT_SMALL, Palette.TEXT_SECONDARY)
	v.add_child(body)

	v.add_child(UI.make_spacer(Palette.SP_SM))

	var btn := UI.make_button("Choose this start", "primary")
	btn.pressed.connect(_on_bg_chosen.bind(key))
	v.add_child(btn)

	return panel

func _on_bg_chosen(key: String) -> void:
	GameState.reset_for_new_game(key)
	get_tree().change_scene_to_file("res://scenes/house_hub.tscn")

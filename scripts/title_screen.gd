extends Control

func _ready() -> void:
	_build()

func _build() -> void:
	# Page background
	var bg := ColorRect.new()
	bg.color = Palette.BG_PAGE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Decorative motif: faded saffron strip on the left edge — Salamia's
	# visual signature (echoed in every screen).
	var strip := ColorRect.new()
	strip.color = Color(Palette.SAFFRON.r, Palette.SAFFRON.g, Palette.SAFFRON.b, 0.35)
	strip.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	strip.size.x = 12
	strip.offset_right = 12
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", Palette.SP_LG)
	col.custom_minimum_size.x = 720
	center.add_child(col)

	# Eyebrow
	var eyebrow := UI.make_title_label("THE FEDERAL REPUBLIC OF", Palette.FONT_SMALL, Palette.TEXT_MUTED)
	eyebrow.add_theme_constant_override("outline_size", 0)
	col.add_child(eyebrow)

	# Title
	col.add_child(UI.make_title_label("Salamia", Palette.FONT_TITLE, Palette.TEXT_PRIMARY))

	# Subtitle
	var sub := UI.make_title_label("Grassroots Rising", Palette.FONT_HEADING, Palette.TERRACOTTA)
	col.add_child(sub)

	col.add_child(UI.make_spacer(8))

	# Tagline
	var tag := UI.make_body_label(
		"[center][i]Democracy is not just voting.\nIt is funding.[/i][/center]",
		Palette.FONT_SUBHEAD, Palette.TEXT_SECONDARY
	)
	col.add_child(tag)

	col.add_child(UI.make_spacer(Palette.SP_LG))

	# Buttons row
	var btn_row := VBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", Palette.SP_SM)
	col.add_child(btn_row)

	var begin := UI.make_button("Begin a New Career", "primary")
	begin.custom_minimum_size = Vector2(320, 56)
	begin.pressed.connect(_on_new_game)
	btn_row.add_child(begin)

	var cont := UI.make_button("Continue", "ghost")
	cont.custom_minimum_size = Vector2(320, 48)
	cont.disabled = not GameState.has_save()
	cont.pressed.connect(_on_continue)
	btn_row.add_child(cont)

	# Footer
	var footer_box := MarginContainer.new()
	footer_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer_box.offset_top = -48
	footer_box.add_theme_constant_override("margin_left", Palette.SP_LG)
	footer_box.add_theme_constant_override("margin_right", Palette.SP_LG)
	footer_box.add_theme_constant_override("margin_bottom", Palette.SP_MD)
	add_child(footer_box)

	var footer := UI.make_body_label(
		"[right]spike build · aryavarta state · volunteer → councillor[/right]",
		Palette.FONT_SMALL, Palette.TEXT_MUTED
	)
	footer_box.add_child(footer)

func _on_new_game() -> void:
	# Skip the text intro — drop straight into the walkable ward with
	# default "modest" background. Background choice can move in-world
	# later.
	GameState.reset_for_new_game("modest")
	get_tree().change_scene_to_file("res://scenes/ward.tscn")

func _on_continue() -> void:
	if GameState.load_game():
		get_tree().change_scene_to_file("res://scenes/ward.tscn")

extends Control
##
## Scenario screen: shows the narrative card + choices, then transitions to
## a consequence display before returning to the hub.
##

var scenario: Dictionary
var choices_col: VBoxContainer
var consequence_panel: PanelContainer
var content_root: VBoxContainer
var prompt_label: Control

func _ready() -> void:
	scenario = get_tree().get_meta("pending_scenario", {})
	if scenario.is_empty():
		# nothing to show — bounce back
		get_tree().change_scene_to_file("res://scenes/house_hub.tscn")
		return
	_build()
	_fade_in()

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

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 32
	scroll.offset_right = -32
	scroll.offset_top = 24
	scroll.offset_bottom = -24
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	content_root = VBoxContainer.new()
	content_root.custom_minimum_size.x = 820
	content_root.add_theme_constant_override("separation", Palette.SP_MD)
	center.add_child(content_root)

	# Title row
	var eyebrow := Label.new()
	eyebrow.text = "%s · %s" % [GameState.position_title().to_upper(), str(scenario.get("speaker", "")).to_upper()]
	eyebrow.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	eyebrow.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	content_root.add_child(eyebrow)

	var title := Label.new()
	title.text = scenario.get("title", "")
	title.add_theme_font_size_override("font_size", Palette.FONT_HEADING)
	title.add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
	content_root.add_child(title)

	# Illustration placeholder (vector motif keyed off the scenario)
	content_root.add_child(_make_illustration(scenario.get("scene_icon", "")))

	# Narrative
	var letter := UI.make_letter_panel()
	content_root.add_child(letter)
	var narrative := UI.make_body_label(scenario.get("narrative", ""), Palette.FONT_SUBHEAD, Palette.TEXT_PRIMARY)
	narrative.add_theme_constant_override("line_separation", 8)
	letter.add_child(narrative)

	content_root.add_child(UI.make_spacer(Palette.SP_MD))

	prompt_label = UI.make_body_label("[b]What do you do?[/b]", Palette.FONT_SUBHEAD, Palette.TEXT_PRIMARY)
	content_root.add_child(prompt_label)

	choices_col = VBoxContainer.new()
	choices_col.add_theme_constant_override("separation", Palette.SP_SM)
	content_root.add_child(choices_col)

	var choices: Array = scenario.get("choices", [])
	for i in range(choices.size()):
		var c: Dictionary = choices[i]
		choices_col.add_child(_make_choice_button(c, i))

func _make_choice_button(choice: Dictionary, idx: int) -> Control:
	var available := GameState.meets_requirements(choice.get("requires", {}))

	var btn := Button.new()
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.clip_text = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.custom_minimum_size = Vector2(0, 64)
	btn.add_theme_font_size_override("font_size", Palette.FONT_BODY)
	btn.add_theme_stylebox_override("normal", UI.button_style("choice"))
	btn.add_theme_stylebox_override("hover", UI.button_hover_style("choice"))
	btn.add_theme_stylebox_override("pressed", UI.button_hover_style("choice"))
	btn.add_theme_stylebox_override("focus", UI.button_hover_style("choice"))
	btn.add_theme_stylebox_override("disabled", UI.button_disabled_style("choice"))
	btn.add_theme_color_override("font_color", Palette.TEXT_PRIMARY if available else Palette.TEXT_MUTED)
	btn.add_theme_color_override("font_hover_color", Palette.TEXT_PRIMARY)
	btn.add_theme_color_override("font_pressed_color", Palette.TEXT_PRIMARY)
	btn.add_theme_color_override("font_disabled_color", Palette.TEXT_MUTED)

	var label_text := "%d.    %s" % [idx + 1, choice.get("label", "")]
	if not available:
		var req_text := _format_requires(choice.get("requires", {}))
		if req_text != "":
			label_text += "\n         🔒  " + req_text
	btn.text = label_text
	btn.disabled = not available
	if available:
		btn.pressed.connect(_on_choice.bind(idx))
	return btn

func _format_requires(req: Dictionary) -> String:
	if req.is_empty():
		return ""
	var parts: Array = []
	for k in req.keys():
		var val = req[k]
		match k:
			"min_finances":
				parts.append("requires %s" % UI.format_rupees(int(val)))
			"flag":
				parts.append("requires earlier choice: %s" % str(val).replace("_", " "))
			"not_flag":
				parts.append("blocked by earlier choice: %s" % str(val).replace("_", " "))
			"position":
				parts.append("requires position: %s" % str(val))
			_:
				if k in GameState:
					parts.append("requires %s ≥ %s" % [GameState.STAT_LABELS.get(k, k), str(val)])
				else:
					parts.append("requires %s = %s" % [str(k), str(val)])
	return ", ".join(parts)

func _make_illustration(icon: String) -> Control:
	# A simple decorative band with a glyph drawn from the scenario's icon
	# tag. Placeholder for purchased illustrations in production.
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.BG_CARD_DEEP
	sb.set_corner_radius_all(4)
	sb.content_margin_left = Palette.SP_LG
	sb.content_margin_right = Palette.SP_LG
	sb.content_margin_top = Palette.SP_MD
	sb.content_margin_bottom = Palette.SP_MD
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size.y = 80

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", Palette.SP_LG)
	panel.add_child(h)

	var glyph_label := Label.new()
	glyph_label.text = _icon_glyph(icon)
	glyph_label.add_theme_font_size_override("font_size", 40)
	glyph_label.add_theme_color_override("font_color", Palette.TERRACOTTA)
	h.add_child(glyph_label)

	var divider := ColorRect.new()
	divider.color = Palette.BORDER_DARK
	divider.custom_minimum_size = Vector2(1, 48)
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(divider)

	var caption := Label.new()
	caption.text = _icon_caption(icon)
	caption.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	caption.add_theme_color_override("font_color", Palette.TEXT_SECONDARY)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(caption)

	return panel

func _icon_glyph(icon: String) -> String:
	match icon:
		"tap":      return "≀"
		"smoke":    return "☁"
		"scales":   return "⚖"
		"file":     return "✉"
		"card":     return "✦"
		"ledger":   return "✎"
		"envelope": return "✉"
		"road":     return "═"
		"crowd":    return "✺"
	return "✦"

func _icon_caption(icon: String) -> String:
	match icon:
		"tap":      return "A neighbourhood matter. Small. Defining."
		"smoke":    return "A crowd has gathered. The press has too."
		"scales":   return "An old fight over earth, paper, and caste."
		"file":     return "An eight-month file. Two rubber bands. One pension."
		"card":     return "An invitation that is not quite an invitation."
		"ledger":   return "Numbers. And the silence around them."
		"envelope": return "A document that should not have left the ministry."
		"road":     return "Three bids. One question."
		"crowd":    return "Three hundred families on one square."
	return "A choice presents itself."

# --------------------------------------------------------------------------
# Choice flow
# --------------------------------------------------------------------------
func _on_choice(idx: int) -> void:
	var choices: Array = scenario.get("choices", [])
	if idx < 0 or idx >= choices.size():
		return
	var choice: Dictionary = choices[idx]

	var effects: Dictionary = choice.get("effects", {})
	GameState.apply_effects(effects)

	if choice.has("flag"):
		GameState.set_flag(str(choice["flag"]))
	if choice.has("unlocks"):
		for u in choice["unlocks"]:
			GameState.unlock_scenario(str(u))

	GameState.mark_completed(str(scenario.get("id", "")))

	_show_consequence(choice, effects)

func _show_consequence(choice: Dictionary, effects: Dictionary) -> void:
	# Hide the choice section entirely — the consequence takes its place.
	prompt_label.visible = false
	choices_col.visible = false

	# Build a fresh consequence card
	consequence_panel = UI.make_panel(true)
	content_root.add_child(consequence_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Palette.SP_MD)
	consequence_panel.add_child(v)

	var head := Label.new()
	head.text = "WHAT FOLLOWS"
	head.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	head.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	v.add_child(head)

	var followup_text := str(choice.get("followup", ""))
	if followup_text != "":
		var fu := UI.make_body_label(followup_text, Palette.FONT_SUBHEAD, Palette.TEXT_PRIMARY)
		fu.add_theme_constant_override("line_separation", 6)
		v.add_child(fu)

	if not effects.is_empty():
		v.add_child(UI.make_divider())
		var label := Label.new()
		label.text = "Consequences"
		label.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
		label.add_theme_color_override("font_color", Palette.TEXT_MUTED)
		v.add_child(label)

		var chip_box := HFlowContainer.new()
		chip_box.add_theme_constant_override("h_separation", Palette.SP_SM)
		chip_box.add_theme_constant_override("v_separation", Palette.SP_SM)
		v.add_child(chip_box)

		for key in effects.keys():
			var val: int = int(effects[key])
			if val == 0:
				continue
			chip_box.add_child(_make_chip(key, val))

	v.add_child(UI.make_spacer(Palette.SP_SM))

	var cont := UI.make_button("Continue", "primary")
	cont.pressed.connect(func():
		var ret := get_tree().get_meta("return_scene", "res://scenes/ward.tscn")
		get_tree().change_scene_to_file(ret)
	)
	v.add_child(cont)

	# Tween the panel in
	consequence_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(consequence_panel, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)

func _make_chip(key: String, val: int) -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	var positive := val > 0
	if key == "finances":
		# Spending money is rarely "bad" if it bought integrity — render
		# financial deltas in a neutral indigo so they don't read as moral
		sb.bg_color = Palette.INDIGO.lightened(0.55)
		sb.border_color = Palette.INDIGO
	elif positive:
		sb.bg_color = Color(Palette.OLIVE_DEEP.r, Palette.OLIVE_DEEP.g, Palette.OLIVE_DEEP.b, 0.18)
		sb.border_color = Palette.OLIVE_DEEP
	else:
		sb.bg_color = Color(Palette.RUST.r, Palette.RUST.g, Palette.RUST.b, 0.15)
		sb.border_color = Palette.RUST
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(1)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	var nice_key := GameState.STAT_LABELS.get(key, key.capitalize())
	if key == "finances":
		lbl.text = "%s %s" % ["+" if val > 0 else "−", UI.format_rupees(absi(val))]
	else:
		lbl.text = "%s%d  %s" % ["+" if val > 0 else "", val, nice_key]
	lbl.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	var text_color: Color
	if key == "finances":
		text_color = Palette.INDIGO
	elif positive:
		text_color = Palette.OLIVE_DEEP
	else:
		text_color = Palette.RUST
	lbl.add_theme_color_override("font_color", text_color)
	panel.add_child(lbl)
	return panel

func _fade_in() -> void:
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)

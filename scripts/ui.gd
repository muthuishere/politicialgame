class_name UI
##
## Small library of helpers that build cards, buttons, dividers etc. in the
## Salamia visual vocabulary. Keeps screens declarative — every screen builds
## its UI in code (no .tscn hand-editing per screen) and uses these helpers
## so the look stays uniform.
##

# === StyleBoxes ===
static func card_style(deep: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.BG_CARD_DEEP if deep else Palette.BG_CARD
	sb.border_color = Palette.BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = Palette.SP_LG
	sb.content_margin_right = Palette.SP_LG
	sb.content_margin_top = Palette.SP_MD
	sb.content_margin_bottom = Palette.SP_MD
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	return sb

static func letter_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.BG_CARD
	sb.border_color = Palette.BORDER_DARK
	sb.set_border_width_all(1)
	sb.border_width_left = 4
	sb.set_corner_radius_all(2)
	sb.content_margin_left = Palette.SP_XL
	sb.content_margin_right = Palette.SP_XL
	sb.content_margin_top = Palette.SP_LG
	sb.content_margin_bottom = Palette.SP_LG
	sb.shadow_color = Color(0, 0, 0, 0.15)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(2, 4)
	return sb

static func button_style(variant: String = "primary") -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	match variant:
		"primary":
			sb.bg_color = Palette.TEXT_PRIMARY
			sb.border_color = Palette.TEXT_PRIMARY
		"accent":
			sb.bg_color = Palette.SAFFRON
			sb.border_color = Palette.SAFFRON.darkened(0.2)
		"ghost":
			sb.bg_color = Color(0, 0, 0, 0)
			sb.border_color = Palette.BORDER_DARK
		"choice":
			sb.bg_color = Palette.BG_CARD
			sb.border_color = Palette.BORDER_DARK
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = Palette.SP_LG
	sb.content_margin_right = Palette.SP_LG
	sb.content_margin_top = Palette.SP_MD
	sb.content_margin_bottom = Palette.SP_MD
	return sb

static func button_hover_style(variant: String = "primary") -> StyleBoxFlat:
	var sb := button_style(variant)
	match variant:
		"primary":
			sb.bg_color = Palette.TEXT_PRIMARY.lightened(0.15)
		"accent":
			sb.bg_color = Palette.SAFFRON.lightened(0.1)
		"ghost":
			sb.bg_color = Color(Palette.TEXT_PRIMARY.r, Palette.TEXT_PRIMARY.g, Palette.TEXT_PRIMARY.b, 0.08)
		"choice":
			sb.bg_color = Palette.BG_CARD_DEEP
			sb.border_color = Palette.SAFFRON.darkened(0.2)
	return sb

static func button_disabled_style(variant: String = "primary") -> StyleBoxFlat:
	var sb := button_style(variant)
	sb.bg_color.a = 0.35
	sb.border_color.a = 0.35
	return sb

# === Component factories ===
static func make_title_label(text: String, size: int = Palette.FONT_TITLE, color: Color = Palette.TEXT_PRIMARY) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

static func make_body_label(text: String, size: int = Palette.FONT_BODY, color: Color = Palette.TEXT_PRIMARY) -> RichTextLabel:
	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.text = text
	lbl.add_theme_font_size_override("normal_font_size", size)
	lbl.add_theme_font_size_override("bold_font_size", size)
	lbl.add_theme_font_size_override("italics_font_size", size)
	lbl.add_theme_color_override("default_color", color)
	return lbl

static func make_button(text: String, variant: String = "primary") -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_color_override("font_color", Palette.TEXT_INVERSE if variant == "primary" or variant == "accent" else Palette.TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", btn.get_theme_color("font_color"))
	btn.add_theme_color_override("font_pressed_color", btn.get_theme_color("font_color"))
	btn.add_theme_color_override("font_focus_color", btn.get_theme_color("font_color"))
	btn.add_theme_color_override("font_disabled_color", Palette.TEXT_MUTED)
	btn.add_theme_font_size_override("font_size", Palette.FONT_BUTTON)
	btn.add_theme_stylebox_override("normal", button_style(variant))
	btn.add_theme_stylebox_override("hover", button_hover_style(variant))
	btn.add_theme_stylebox_override("pressed", button_hover_style(variant))
	btn.add_theme_stylebox_override("focus", button_hover_style(variant))
	btn.add_theme_stylebox_override("disabled", button_disabled_style(variant))
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn

static func make_panel(deep: bool = false) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", card_style(deep))
	return p

static func make_letter_panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", letter_style())
	return p

static func make_divider() -> HSeparator:
	var sep := HSeparator.new()
	var line := StyleBoxLine.new()
	line.color = Palette.BORDER
	line.thickness = 1
	sep.add_theme_stylebox_override("separator", line)
	sep.custom_minimum_size.y = 1
	return sep

static func make_spacer(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = height
	return c

static func format_rupees(amount: int) -> String:
	# Indian numbering: 1,23,456 not 123,456
	var negative := amount < 0
	var n := absi(amount)
	var s := str(n)
	if s.length() <= 3:
		return ("-₹" if negative else "₹") + s
	var last3 := s.substr(s.length() - 3, 3)
	var rest := s.substr(0, s.length() - 3)
	var pieces: Array = []
	while rest.length() > 2:
		pieces.push_front(rest.substr(rest.length() - 2, 2))
		rest = rest.substr(0, rest.length() - 2)
	if rest.length() > 0:
		pieces.push_front(rest)
	var formatted: String = ",".join(pieces) + "," + last3
	return ("-₹" if negative else "₹") + formatted

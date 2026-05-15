extends PanelContainer
##
## Reusable side panel that renders all three tracks. Wired to GameState
## signals so it rerenders on stat change.
##

class_name StatsPanel

var personal_box: VBoxContainer
var official_box: VBoxContainer
var financial_lbl: Label
var position_lbl: Label

func _ready() -> void:
	add_theme_stylebox_override("panel", UI.card_style())
	custom_minimum_size = Vector2(300, 0)
	_build()
	GameState.stat_changed.connect(func(_t, _s, _d, _v): _refresh())
	GameState.finances_changed.connect(func(_d, _v): _refresh())
	GameState.position_changed.connect(func(_p): _refresh())

func _build() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Palette.SP_SM)
	add_child(v)

	# Header
	var eyebrow := Label.new()
	eyebrow.text = "YOUR STANDING"
	eyebrow.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	eyebrow.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	v.add_child(eyebrow)

	position_lbl = Label.new()
	position_lbl.add_theme_font_size_override("font_size", Palette.FONT_HEADING)
	position_lbl.add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
	v.add_child(position_lbl)

	v.add_child(UI.make_divider())

	# Personal
	v.add_child(_section_header("Personal"))
	personal_box = VBoxContainer.new()
	personal_box.add_theme_constant_override("separation", 2)
	v.add_child(personal_box)

	v.add_child(UI.make_spacer(Palette.SP_SM))
	v.add_child(UI.make_divider())

	# Official
	v.add_child(_section_header("Official"))
	official_box = VBoxContainer.new()
	official_box.add_theme_constant_override("separation", 4)
	v.add_child(official_box)

	v.add_child(UI.make_spacer(Palette.SP_SM))
	v.add_child(UI.make_divider())

	# Financial
	v.add_child(_section_header("Funds"))
	financial_lbl = Label.new()
	financial_lbl.add_theme_font_size_override("font_size", Palette.FONT_HEADING)
	financial_lbl.add_theme_color_override("font_color", Palette.OLIVE_DEEP)
	v.add_child(financial_lbl)

	_refresh()

func _section_header(text: String) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	l.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	return l

func _refresh() -> void:
	position_lbl.text = GameState.position_title()
	financial_lbl.text = UI.format_rupees(GameState.finances)
	financial_lbl.add_theme_color_override(
		"font_color",
		Palette.RUST if GameState.finances < 0 else Palette.OLIVE_DEEP
	)

	# Personal — prose, not numbers
	for c in personal_box.get_children():
		c.queue_free()
	for stat in GameState.PERSONAL_STATS:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		var name_lbl := Label.new()
		name_lbl.text = GameState.STAT_LABELS[stat]
		name_lbl.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
		name_lbl.add_theme_color_override("font_color", Palette.TEXT_SECONDARY)
		row.add_child(name_lbl)
		var desc_lbl := Label.new()
		desc_lbl.text = GameState.describe(stat)
		desc_lbl.add_theme_font_size_override("font_size", Palette.FONT_BODY)
		desc_lbl.add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(desc_lbl)
		personal_box.add_child(row)
		personal_box.add_child(UI.make_spacer(4))

	# Official — bars
	for c in official_box.get_children():
		c.queue_free()
	for stat in GameState.OFFICIAL_STATS:
		official_box.add_child(_stat_bar(stat))

func _stat_bar(stat: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)

	var row := HBoxContainer.new()
	v.add_child(row)

	var name_lbl := Label.new()
	name_lbl.text = GameState.STAT_LABELS[stat]
	name_lbl.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	name_lbl.add_theme_color_override("font_color", Palette.TEXT_SECONDARY)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)

	var val_lbl := Label.new()
	val_lbl.text = str(int(GameState.get(stat)))
	val_lbl.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	val_lbl.add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
	row.add_child(val_lbl)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = int(GameState.get(stat))
	bar.show_percentage = false
	bar.custom_minimum_size.y = 6

	var bg := StyleBoxFlat.new()
	bg.bg_color = Palette.BG_CARD_DEEP
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)

	var fg := StyleBoxFlat.new()
	fg.bg_color = Palette.OLIVE if stat != "reform_progress" else Palette.SAFFRON
	fg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fg)

	v.add_child(bar)
	return v

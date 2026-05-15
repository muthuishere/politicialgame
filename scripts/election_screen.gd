extends Control
##
## Ward councillor election. Two phases:
##   1. Campaign budget allocation — player decides what to spend.
##   2. Result calculation + narrative.
##
## Vote share is a function of local_trust, party support (depending on
## alignment flags), integrity floor, campaign spend, and a small random
## factor. Designed so a principled, well-trusted player CAN win on
## independent ticket; a corrupt one needs party backing to coast.
##

const RIVAL_NAME := "Suresh Tiwari"
const RIVAL_BASE_VOTE := 35

var phase: String = "allocate"  # allocate | result
var spend: int = 0
var content: VBoxContainer

func _ready() -> void:
	_build_background()
	_render_allocate()

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG_PAGE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var strip := ColorRect.new()
	strip.color = Palette.SAFFRON
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

	content = VBoxContainer.new()
	content.custom_minimum_size.x = 820
	content.add_theme_constant_override("separation", Palette.SP_MD)
	center.add_child(content)

func _clear_content() -> void:
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()

func _set_slider_value(slider: HSlider, amount: int) -> void:
	slider.value = amount

func _alignment_label() -> String:
	if GameState.has_flag("ajm_aligned"): return "Aryavarta Janata Manch (AJM) ticket"
	if GameState.has_flag("ajm_loose"):   return "AJM-supported independent"
	if GameState.has_flag("bls_aligned"): return "Bharat Lok Sabha (BLS) ticket"
	if GameState.has_flag("independent"): return "Independent candidate"
	return "Unaffiliated candidate"

# --------------------------------------------------------------------------
# Phase 1 — allocate spend
# --------------------------------------------------------------------------
func _render_allocate() -> void:
	_clear_content()

	var eyebrow := Label.new()
	eyebrow.text = "WARD ELECTION · ARYAVARTA"
	eyebrow.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	eyebrow.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	content.add_child(eyebrow)

	var title := Label.new()
	title.text = "Three Weeks to Polling Day"
	title.add_theme_font_size_override("font_size", Palette.FONT_HEADING)
	title.add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
	content.add_child(title)

	var letter := UI.make_letter_panel()
	content.add_child(letter)

	var n := UI.make_body_label(
		"You are running as: [b]%s[/b].\n\nYour funds available for the campaign: [b]%s[/b].\nYour rival is [b]%s[/b] — a four-time incumbent, well-organised, well-funded, with a reputation for delivering small favours and ignoring large problems.\n\nMost wards in Aryavarta are won not by money but by faces — by who is seen on which corner with whom. Still, money buys hoardings, autorickshaw loops, a tea-stall presence. Spend what you think is right.\n\n[i]A modest, principled campaign and a strong ward presence can beat a well-funded one. But not always.[/i]" % [
			_alignment_label(), UI.format_rupees(GameState.finances), RIVAL_NAME
		],
		Palette.FONT_SUBHEAD, Palette.TEXT_PRIMARY
	)
	n.add_theme_constant_override("line_separation", 6)
	letter.add_child(n)

	content.add_child(UI.make_spacer(Palette.SP_SM))

	var budget_card := UI.make_panel()
	content.add_child(budget_card)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", Palette.SP_SM)
	budget_card.add_child(bv)

	var h := Label.new()
	h.text = "Campaign budget"
	h.add_theme_font_size_override("font_size", Palette.FONT_SUBHEAD)
	h.add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
	bv.add_child(h)

	var current_amt := UI.make_body_label("[b]%s[/b]   [i]of %s available[/i]" % [UI.format_rupees(spend), UI.format_rupees(GameState.finances)], Palette.FONT_SUBHEAD, Palette.TERRACOTTA)
	current_amt.name = "AmountLabel"
	bv.add_child(current_amt)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = GameState.finances
	slider.step = 1000
	slider.value = clampi(spend, 0, GameState.finances)
	slider.custom_minimum_size.y = 32
	slider.value_changed.connect(func(v):
		spend = int(v)
		current_amt.text = "[b]%s[/b]   [i]of %s available[/i]" % [UI.format_rupees(spend), UI.format_rupees(GameState.finances)]
	)
	bv.add_child(slider)

	bv.add_child(UI.make_divider())

	var presets := HBoxContainer.new()
	presets.add_theme_constant_override("separation", Palette.SP_SM)
	bv.add_child(presets)

	for amount in [0, 10000, 25000, 50000, 100000]:
		if amount > GameState.finances and amount > 0:
			continue
		var btn := UI.make_button(UI.format_rupees(amount), "ghost")
		# Bind the amount at button-creation time — otherwise the lambda would
		# capture the loop variable by reference and every button would set
		# the slider to the final iteration's value.
		btn.pressed.connect(_set_slider_value.bind(slider, amount))
		presets.add_child(btn)

	var hint := UI.make_body_label(
		"[i]Spending zero is permitted. Many wards have been won that way. Spending everything is also permitted. Few wards have been won that way and still felt like wins.[/i]",
		Palette.FONT_SMALL, Palette.TEXT_MUTED
	)
	hint.add_theme_constant_override("line_separation", 4)
	bv.add_child(hint)

	content.add_child(UI.make_spacer(Palette.SP_SM))

	var go := UI.make_button("Polling day — count the votes", "accent")
	go.custom_minimum_size.y = 52
	go.pressed.connect(_run_election)
	content.add_child(go)

# --------------------------------------------------------------------------
# Phase 2 — run + render
# --------------------------------------------------------------------------
func _run_election() -> void:
	# Deduct campaign spend
	if spend > 0:
		GameState.apply_effects({"finances": -spend})

	# Calculate vote share for player
	var player_score := _player_vote_score(spend)
	var rival_score := _rival_vote_score()
	var other := 100 - player_score - rival_score
	if other < 0:
		# normalise
		var sum_pl_rv := player_score + rival_score
		player_score = int(player_score * 100.0 / sum_pl_rv)
		rival_score = 100 - player_score
		other = 0

	var won := player_score > rival_score
	_render_result(player_score, rival_score, other, won)

func _player_vote_score(spend_amt: int) -> int:
	var base := 12.0
	base += GameState.local_trust * 0.55  # primary driver
	base += GameState.media_reputation * 0.20
	base += GameState.empathy * 0.08

	# Party support
	if GameState.has_flag("ajm_aligned"):       base += 18
	elif GameState.has_flag("ajm_loose"):       base += 10
	elif GameState.has_flag("bls_aligned"):     base += 12
	elif GameState.has_flag("independent"):     base += 0
	if GameState.party_loyalty >= 30:           base += 4

	# Money — diminishing returns, capped
	var money_boost := min(15.0, spend_amt / 6000.0)
	base += money_boost

	# Integrity penalty: very low integrity costs you (the ward gossips)
	if GameState.integrity < 30:
		base -= (30 - GameState.integrity) * 0.4

	# Punishment for blatant evasion early on
	if GameState.has_flag("early_evasion"):
		base -= 4

	# Slight random factor — politics is politics
	base += randf_range(-3.0, 3.0)

	return int(clampf(base, 5, 78))

func _rival_vote_score() -> int:
	var r := float(RIVAL_BASE_VOTE)
	# Aligned with the same major party? Then he splits his own base less
	if GameState.has_flag("ajm_aligned") or GameState.has_flag("ajm_loose"):
		r -= 8  # Tiwari (AJM-leaning) gets undercut
	r += randf_range(-4.0, 4.0)
	return int(clampf(r, 18, 55))

func _render_result(player_score: int, rival_score: int, other: int, won: bool) -> void:
	_clear_content()

	var eyebrow := Label.new()
	eyebrow.text = "POLLING DAY · LATE EVENING"
	eyebrow.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	eyebrow.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	content.add_child(eyebrow)

	var title := Label.new()
	title.text = "You won the ward." if won else "It was close. It was not enough."
	title.add_theme_font_size_override("font_size", Palette.FONT_HEADING)
	title.add_theme_color_override("font_color", Palette.OLIVE_DEEP if won else Palette.RUST)
	content.add_child(title)

	var card := UI.make_panel()
	content.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Palette.SP_SM)
	card.add_child(v)

	v.add_child(_vote_row(GameState.protagonist_name + " (you)", player_score, Palette.OLIVE_DEEP if won else Palette.TERRACOTTA))
	v.add_child(_vote_row(RIVAL_NAME + " (incumbent)", rival_score, Palette.INDIGO))
	if other > 0:
		v.add_child(_vote_row("Others", other, Palette.TEXT_MUTED))

	# Narrative card
	var letter := UI.make_letter_panel()
	content.add_child(letter)
	var narrative := _narrative_for_result(won, player_score, rival_score)
	var body := UI.make_body_label(narrative, Palette.FONT_SUBHEAD, Palette.TEXT_PRIMARY)
	body.add_theme_constant_override("line_separation", 6)
	letter.add_child(body)

	# Apply consequences
	if won:
		GameState.advance_position()
		GameState.apply_effects({"reform_progress": 5, "media_reputation": 8, "local_trust": 6})
		GameState.set_flag("won_ward_election")
	else:
		GameState.apply_effects({"inner_peace": -10, "family_harmony": -6, "local_trust": -4, "media_reputation": -4})

	content.add_child(UI.make_spacer(Palette.SP_SM))
	var cont := UI.make_button("Continue" if won else "Return home", "primary")
	cont.custom_minimum_size.y = 52
	if won:
		cont.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/house_hub.tscn"))
	else:
		cont.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ending.tscn"))
	content.add_child(cont)

	GameState.save_game()

func _vote_row(name: String, pct: int, color: Color) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)

	var row := HBoxContainer.new()
	v.add_child(row)

	var name_lbl := Label.new()
	name_lbl.text = name
	name_lbl.add_theme_font_size_override("font_size", Palette.FONT_BODY)
	name_lbl.add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)

	var pct_lbl := Label.new()
	pct_lbl.text = "%d%%" % pct
	pct_lbl.add_theme_font_size_override("font_size", Palette.FONT_SUBHEAD)
	pct_lbl.add_theme_color_override("font_color", color)
	row.add_child(pct_lbl)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = pct
	bar.show_percentage = false
	bar.custom_minimum_size.y = 10

	var bg := StyleBoxFlat.new()
	bg.bg_color = Palette.BG_CARD_DEEP
	bg.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", bg)

	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("fill", fg)

	v.add_child(bar)
	return v

func _narrative_for_result(won: bool, player: int, rival: int) -> String:
	if won:
		var margin := player - rival
		if margin >= 15:
			return "By 11 PM the count is no longer in doubt. Bashir-bhai is laughing. Mrs. Devi is crying. Someone has lit fireworks they cannot afford. You take the oath the next morning in a room that smells of old paper and ceiling fans. There is a brass plate. It has your name on it.\n\n[i]You are now a Ward Councillor. The first real ledger lands on your desk tomorrow.[/i]"
		else:
			return "Slim. Slimmer than the party offices expected. The deciding bundles arrive after midnight, from booth 27 — the one near the tap that no longer leaks. Tiwari calls to concede at 1:14 AM. He is polite, which is unsettling.\n\n[i]You are now a Ward Councillor. By the narrowest of margins — which means every vote in the chamber will matter.[/i]"
	else:
		if rival - player <= 6:
			return "Close. Painfully close. Eight hundred and thirty-one votes. Tiwari's people are setting off firecrackers two streets away. Bashir-bhai sits on his stool by the cleared corner and says nothing for a long time.\n\n[i]A future is still possible — but this chapter ends here.[/i]"
		else:
			return "The ward, as it turns out, was not as ready as it seemed. Tiwari's machine held. The hoardings came down by Sunday afternoon. Your father, surprisingly, did not say I told you so — which was harder than if he had.\n\n[i]A future is still possible — but this chapter ends here.[/i]"

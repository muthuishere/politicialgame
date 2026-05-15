extends Control
##
## End-of-spike card. Computes a "shape" based on personal vs official score
## and shows a closing reflection.
##

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG_PAGE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var strip := ColorRect.new()
	strip.color = Palette.TERRACOTTA
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

	var col := VBoxContainer.new()
	col.custom_minimum_size.x = 780
	col.add_theme_constant_override("separation", Palette.SP_MD)
	center.add_child(col)

	var eyebrow := Label.new()
	eyebrow.text = "END OF SPIKE · CHAPTER ONE OF MANY"
	eyebrow.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	eyebrow.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	col.add_child(eyebrow)

	var personal := _personal_score()
	var official := _official_score()
	var shape := _shape_for(personal, official)

	var title := Label.new()
	title.text = shape["title"]
	title.add_theme_font_size_override("font_size", Palette.FONT_TITLE)
	title.add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
	col.add_child(title)

	var subtitle := UI.make_body_label(
		"[i]%s[/i]" % shape["epithet"],
		Palette.FONT_SUBHEAD, Palette.TERRACOTTA
	)
	col.add_child(subtitle)

	var letter := UI.make_letter_panel()
	col.add_child(letter)

	var body := UI.make_body_label(
		shape["body"] + "\n\n" + _state_summary(),
		Palette.FONT_SUBHEAD, Palette.TEXT_PRIMARY
	)
	body.add_theme_constant_override("line_separation", 6)
	letter.add_child(body)

	# Replay hint
	col.add_child(UI.make_spacer(Palette.SP_MD))

	var tease := UI.make_body_label(
		"[b]The Story Continues —[/b]\n\nThe full game lifts you from this ward office through state assemblies, ministerial portfolios, the office of the Chief Minister, and eventually toward the Prime Minister's residence. Eight other states wait — each with their own opening, their own scandals, their own way of breaking a young reformer. The Local Revenue Empowerment Act — that 10% local share of NST — is still a sentence in a draft document. Whether it becomes law, and what it costs you to get it there, is the rest of [i]Salamia[/i].",
		Palette.FONT_BODY, Palette.TEXT_SECONDARY
	)
	tease.add_theme_constant_override("line_separation", 4)
	col.add_child(tease)

	col.add_child(UI.make_spacer(Palette.SP_MD))

	var play_again := UI.make_button("Try a different path", "accent")
	play_again.custom_minimum_size.y = 52
	play_again.pressed.connect(func():
		# Wipe save and return to title
		if FileAccess.file_exists(GameState.SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
		get_tree().change_scene_to_file("res://scenes/title.tscn")
	)
	col.add_child(play_again)

	var back := UI.make_button("Return to title", "ghost")
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/title.tscn"))
	col.add_child(back)

func _personal_score() -> int:
	return int((GameState.integrity + GameState.empathy + GameState.local_trust + GameState.family_harmony + GameState.inner_peace) / 5.0)

func _official_score() -> int:
	# Includes position weight
	var pos_w := GameState.POSITIONS.find(GameState.position) * 12
	return int(clampi(pos_w + GameState.media_reputation * 0.3 + GameState.coalition_strength * 0.3 + GameState.reform_progress * 0.4, 0, 100))

func _shape_for(personal: int, official: int) -> Dictionary:
	var p_band := "high" if personal >= 60 else ("mid" if personal >= 40 else "low")
	var o_band := "high" if official >= 60 else ("mid" if official >= 40 else "low")

	if p_band == "high" and o_band == "high":
		return {
			"title": "The Reformer",
			"epithet": "Power held, hands clean. So far.",
			"body": "You won the ward and kept your face. Bashir-bhai will still meet your eye on the road. Your spouse still meets you at the door. The Local Revenue Empowerment Act — that 10% — has, in this version of you, a first real champion at the ward level. It is the hardest path. It is also, by some measures, the only one that ever changes anything."
		}
	if p_band == "high" and o_band == "mid":
		return {
			"title": "The Quiet Steward",
			"epithet": "Loved more than respected. For now.",
			"body": "You did the work and refused the shortcuts. The ward knows you. The party offices have a thinner file on you than they would like. The bigger doors have not opened — but you are not yet at an age where they need to."
		}
	if p_band == "high" and o_band == "low":
		return {
			"title": "The Martyr",
			"epithet": "Crushed by the system. Remembered by the ward.",
			"body": "Every fight you picked was the right one and none of them paid out in the currency that gets people elected. There will be others, later, who cite you in their speeches. You will not be there to hear them. But the ward remembers, and that is not nothing."
		}
	if p_band == "mid" and o_band == "high":
		return {
			"title": "The Pragmatist",
			"epithet": "A useful person to have in a difficult room.",
			"body": "You traded — small things, mostly, things you can live with. The ward got fewer leaking taps. The party got a reliable signature. You got a brass plate on your door. The 10% is, for you, a slogan you would gladly use if it became available, and not a thing you have yet bled for."
		}
	if p_band == "mid" and o_band == "mid":
		return {
			"title": "The Survivor",
			"epithet": "Still standing. That is its own achievement.",
			"body": "Neither side claims you and neither side has yet destroyed you. In Aryavarta this is, by itself, a respectable career so far."
		}
	if p_band == "low" and o_band == "high":
		return {
			"title": "The Puppet",
			"epithet": "Powerful. And bought.",
			"body": "Your office has a flag. Your bank account has weight. Your sleep is uneven. Somewhere in a steel almirah is an envelope you took. The 10% law, if it ever passes, will pass over your name without your consent — by reformers who do not exist in this version of the story."
		}
	if p_band == "low" and o_band == "mid":
		return {
			"title": "The Turncoat",
			"epithet": "No one trusts you. No one fully discards you.",
			"body": "You changed sides too often. Each side remembers — and reaches out only when they want something they can throw away afterwards."
		}
	return {
		"title": "The Cautionary Tale",
		"epithet": "A story other young volunteers tell to caution each other.",
		"body": "Scandal. Defeat. Obscurity. The house your grandmother left you is still yours. The lane still leaks at the corner. Mrs. Devi crosses the road when she sees you."
	}

func _state_summary() -> String:
	var bits: Array = []
	bits.append("Position: [b]%s[/b]." % GameState.position_title())
	bits.append("Reform progress: [b]%d%%[/b] toward the Local Revenue Empowerment Act." % GameState.reform_progress)
	bits.append("Funds on hand: [b]%s[/b]." % UI.format_rupees(GameState.finances))
	var flag_notes: Array = []
	if GameState.has_flag("took_kickback"):     flag_notes.append("the road tender envelope")
	if GameState.has_flag("paid_inspector"):    flag_notes.append("the sanitary inspector you paid")
	if GameState.has_flag("paid_clerk"):        flag_notes.append("the clerk's processing fee")
	if GameState.has_flag("gst_published"):     flag_notes.append("the GST report you made public")
	if GameState.has_flag("gst_private_deal"):  flag_notes.append("the quiet deal on the GST report")
	if GameState.has_flag("stood_with_yadavs"): flag_notes.append("the stand you took for the Yadav family")
	if GameState.has_flag("abandoned_yadavs"):  flag_notes.append("the family you advised to leave")
	if GameState.has_flag("stood_with_vendors"):flag_notes.append("the tempo at Sardar Chowk")
	if GameState.has_flag("forensic_audit"):    flag_notes.append("the audit you called for")
	if GameState.has_flag("transparency_pushed"): flag_notes.append("the contingency line you would not sign")
	if not flag_notes.is_empty():
		bits.append("Things the ward still talks about: " + ", ".join(flag_notes) + ".")
	return "\n".join(bits)

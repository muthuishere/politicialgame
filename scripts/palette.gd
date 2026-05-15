extends Node
##
## Salamia palette + typography constants.
##
## A muted, earthy watercolour-feeling palette evoking ink-on-paper political
## journals. Every screen pulls from here so the spike feels cohesive even
## without purchased illustrations.
##

# === Surfaces ===
const BG_PAGE       := Color("F4E4C6")  # warm cream — the page itself
const BG_CARD       := Color("FAF1DC")  # lighter cream — letters, cards
const BG_CARD_DEEP  := Color("EBD7AE")  # for inset panels
const BG_OVERLAY    := Color(0.184, 0.118, 0.067, 0.55)

# === Strokes / borders ===
const BORDER        := Color("D4B896")
const BORDER_DARK   := Color("8C6E43")

# === Text ===
const TEXT_PRIMARY  := Color("3D2817")  # deep brown
const TEXT_SECONDARY:= Color("6B5642")  # muted brown
const TEXT_MUTED    := Color("8C7556")
const TEXT_INVERSE  := Color("FAF1DC")

# === Semantic accents ===
const SAFFRON       := Color("E89F4E")
const TERRACOTTA    := Color("C97B5C")
const OLIVE         := Color("7A8450")
const OLIVE_DEEP    := Color("5D7C3F")
const RUST          := Color("A85040")
const INDIGO        := Color("4A5D7E")

# Stat colours
const STAT_POSITIVE := Color("5D7C3F")
const STAT_NEGATIVE := Color("A85040")
const STAT_NEUTRAL  := Color("8C7556")

# === Typography sizes ===
const FONT_TITLE    := 56
const FONT_HEADING  := 32
const FONT_SUBHEAD  := 22
const FONT_BODY     := 18
const FONT_SMALL    := 14
const FONT_BUTTON   := 18

# === Spacing ===
const SP_XS := 4
const SP_SM := 8
const SP_MD := 16
const SP_LG := 24
const SP_XL := 40

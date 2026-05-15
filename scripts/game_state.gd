extends Node
##
## GameState: the authoritative store of the player's career.
##
## Everything is in-memory while playing and serialisable to user:// for
## save/load. UI components subscribe to signals and rerender on change —
## there is no global pull-to-refresh.
##

# === Signals ===
signal stat_changed(track: String, stat: String, delta: int, new_value: int)
signal finances_changed(delta: int, new_value: int)
signal position_changed(new_position: String)
signal reform_progress_changed(new_value: int)
signal scenario_completed(scenario_id: String)
signal flag_set(flag_name: String, value: Variant)
signal turn_advanced(new_turn: int)

# === Constants ===
const POSITIONS := ["volunteer", "councillor", "mayor", "mla", "minister", "cm", "pm"]
const POSITION_TITLES := {
	"volunteer": "Volunteer",
	"councillor": "Ward Councillor",
	"mayor": "Mayor",
	"mla": "MLA",
	"minister": "Minister",
	"cm": "Chief Minister",
	"pm": "Prime Minister",
}

const PERSONAL_STATS := ["integrity", "empathy", "local_trust", "family_harmony", "inner_peace"]
const OFFICIAL_STATS := ["party_loyalty", "reform_progress", "media_reputation", "coalition_strength"]
const STAT_LABELS := {
	"integrity": "Integrity",
	"empathy": "Empathy",
	"local_trust": "Local Trust",
	"family_harmony": "Family Harmony",
	"inner_peace": "Inner Peace",
	"party_loyalty": "Party Loyalty",
	"reform_progress": "Reform Progress",
	"media_reputation": "Media Reputation",
	"coalition_strength": "Coalition Strength",
}

const SAVE_PATH := "user://salamia_save.json"

# === Personal Track (0–100, hidden numbers, shown as text in UI) ===
var integrity: int = 50
var empathy: int = 50
var local_trust: int = 20
var family_harmony: int = 60
var inner_peace: int = 60

# === Official Track ===
var position: String = "volunteer"
var party_loyalty: int = 0
var reform_progress: int = 0
var media_reputation: int = 50
var coalition_strength: int = 0

# === Financial Track ===
var finances: int = 50000
var background: String = "modest"  # modest | wealthy

# === Bookkeeping ===
var completed_scenarios: Array = []
var unlocked_scenarios: Array = []
var current_state: String = "aryavarta"
var turn: int = 1
var flags: Dictionary = {}
var protagonist_name: String = "You"
var pending_followup: String = ""

func _ready() -> void:
	randomize()

# --------------------------------------------------------------------------
# Effects application
# --------------------------------------------------------------------------
func apply_effects(effects: Dictionary) -> void:
	for key in effects.keys():
		var delta: int = int(effects[key])
		if key == "finances":
			finances += delta
			finances_changed.emit(delta, finances)
			continue
		if not (key in self):
			push_warning("GameState: unknown effect key '%s'" % key)
			continue
		var old_value: int = int(get(key))
		var new_value: int = old_value + delta
		if key in PERSONAL_STATS or key in OFFICIAL_STATS:
			new_value = clampi(new_value, 0, 100)
		set(key, new_value)
		var actual_delta := new_value - old_value
		var track := _track_for(key)
		stat_changed.emit(track, key, actual_delta, new_value)
		if key == "reform_progress":
			reform_progress_changed.emit(new_value)

func _track_for(key: String) -> String:
	if key in PERSONAL_STATS:
		return "personal"
	if key in OFFICIAL_STATS:
		return "official"
	return "other"

# --------------------------------------------------------------------------
# Flags + requirements
# --------------------------------------------------------------------------
func set_flag(flag_name: String, value: Variant = true) -> void:
	flags[flag_name] = value
	flag_set.emit(flag_name, value)

func has_flag(flag_name: String) -> bool:
	var v: Variant = flags.get(flag_name, false)
	if typeof(v) == TYPE_BOOL:
		return v
	if typeof(v) == TYPE_INT:
		return v != 0
	if typeof(v) == TYPE_STRING:
		return v != ""
	return false

func meets_requirements(req: Dictionary) -> bool:
	for key in req.keys():
		var needed: Variant = req[key]
		match key:
			"min_finances":
				if finances < int(needed):
					return false
			"flag":
				if not has_flag(str(needed)):
					return false
			"not_flag":
				if has_flag(str(needed)):
					return false
			"position":
				if position != str(needed):
					return false
			_:
				if not (key in self):
					push_warning("Unknown requirement key '%s'" % key)
					return false
				if int(get(key)) < int(needed):
					return false
	return true

# --------------------------------------------------------------------------
# Career progression
# --------------------------------------------------------------------------
func advance_position() -> void:
	var idx := POSITIONS.find(position)
	if idx >= 0 and idx < POSITIONS.size() - 1:
		position = POSITIONS[idx + 1]
		position_changed.emit(position)

func position_title() -> String:
	return POSITION_TITLES.get(position, position.capitalize())

func unlock_scenario(scenario_id: String) -> void:
	if scenario_id not in unlocked_scenarios:
		unlocked_scenarios.append(scenario_id)

func mark_completed(scenario_id: String) -> void:
	if scenario_id not in completed_scenarios:
		completed_scenarios.append(scenario_id)
	scenario_completed.emit(scenario_id)

func advance_turn() -> void:
	turn += 1
	turn_advanced.emit(turn)

# --------------------------------------------------------------------------
# Descriptive (prose) stat readouts
# --------------------------------------------------------------------------
##
## Personal stats are intentionally shown as a phrase rather than a number,
## as per the GDD. The same value yields the same phrase deterministically.
##
func describe(stat: String) -> String:
	var v: int = int(get(stat))
	match stat:
		"integrity":
			return _scale(v, [
				"Notorious for taking what isn't theirs",
				"Bends every rule that flexes",
				"Pragmatic about means and ends",
				"Quietly principled",
				"Incorruptible — and feared for it",
			])
		"empathy":
			return _scale(v, [
				"Strangers find them cold",
				"Polite, but distant",
				"Approachable when asked",
				"Warm. People talk to them.",
				"Beloved by neighbours",
			])
		"local_trust":
			return _scale(v, [
				"Nobody in the ward knows their name",
				"A few familiar faces nod hello",
				"Recognised on the main street",
				"Trusted across the ward",
				"The ward's chosen voice",
			])
		"family_harmony":
			return _scale(v, [
				"Home is a battlefield",
				"Tense dinners, silent breakfasts",
				"Quiet, hesitant support",
				"Family stands behind them",
				"The strongest circle they have",
			])
		"inner_peace":
			return _scale(v, [
				"Haunted. Sleepless.",
				"Restless. Always second-guessing.",
				"Holding steady",
				"Unshakable focus",
				"At peace with themselves",
			])
	return ""

func _scale(v: int, levels: Array) -> String:
	var idx := clampi(v / 20, 0, levels.size() - 1)
	return levels[idx]

# --------------------------------------------------------------------------
# New game / save / load
# --------------------------------------------------------------------------
func reset_for_new_game(bg: String) -> void:
	background = bg
	if bg == "wealthy":
		finances = 200000
		family_harmony = 70
		media_reputation = 55  # better connected at start
	else:
		finances = 50000
		family_harmony = 60
		media_reputation = 50
	integrity = 55
	empathy = 55
	local_trust = 20
	inner_peace = 60
	party_loyalty = 0
	reform_progress = 0
	coalition_strength = 0
	position = "volunteer"
	current_state = "aryavarta"
	completed_scenarios.clear()
	unlocked_scenarios.clear()
	turn = 1
	flags.clear()
	pending_followup = ""

func to_dict() -> Dictionary:
	return {
		"integrity": integrity,
		"empathy": empathy,
		"local_trust": local_trust,
		"family_harmony": family_harmony,
		"inner_peace": inner_peace,
		"position": position,
		"party_loyalty": party_loyalty,
		"reform_progress": reform_progress,
		"media_reputation": media_reputation,
		"coalition_strength": coalition_strength,
		"finances": finances,
		"background": background,
		"completed_scenarios": completed_scenarios.duplicate(),
		"unlocked_scenarios": unlocked_scenarios.duplicate(),
		"current_state": current_state,
		"turn": turn,
		"flags": flags.duplicate(true),
	}

func from_dict(d: Dictionary) -> void:
	for key in d.keys():
		if key in self:
			set(key, d[key])

func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file for write")
		return false
	file.store_string(JSON.stringify(to_dict(), "  "))
	file.close()
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var txt := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(txt) != OK:
		return false
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return false
	from_dict(data)
	return true

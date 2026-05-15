extends Node
##
## ScenarioLoader: parses scenarios.json once at boot and serves them up.
##
## Pulling from JSON means non-programmers (designers, you) can write the
## entire content database without touching .gd files. The engine treats
## scenarios as data.
##

const SCENARIO_PATH := "res://data/scenarios.json"

var scenarios: Array = []

func _ready() -> void:
	_load_scenarios()

func _load_scenarios() -> void:
	var file := FileAccess.open(SCENARIO_PATH, FileAccess.READ)
	if file == null:
		push_error("ScenarioLoader: could not open %s" % SCENARIO_PATH)
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("ScenarioLoader: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return
	var data: Variant = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("ScenarioLoader: top-level JSON is not an object")
		return
	scenarios = data.get("scenarios", [])

func get_by_id(id: String) -> Variant:
	for s in scenarios:
		if s.get("id") == id:
			return s
	return null

func eligible_for_phase(phase: String) -> Array:
	var out := []
	for s in scenarios:
		if s.get("phase") != phase:
			continue
		var id: String = s.get("id", "")
		if id in GameState.completed_scenarios:
			continue
		if not GameState.meets_requirements(s.get("requires", {})):
			continue
		out.append(s)
	return out

##
## Picks the next scenario for the current phase. Explicitly-unlocked
## scenarios (set as follow-ups by previous choices) are preferred so
## branching narratives feel deliberate; otherwise we draw randomly from
## the eligible pool.
##
func pick_next_for_phase(phase: String) -> Variant:
	for id in GameState.unlocked_scenarios:
		if id in GameState.completed_scenarios:
			continue
		var s: Variant = get_by_id(id)
		if s != null and s.get("phase") == phase and GameState.meets_requirements(s.get("requires", {})):
			return s
	var pool := eligible_for_phase(phase)
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]

func remaining_for_phase(phase: String) -> int:
	return eligible_for_phase(phase).size()

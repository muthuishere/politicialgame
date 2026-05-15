extends Area2D
##
## NPC standing in the world. When the player enters the talk radius a
## floating "Press E" prompt appears; pressing the interact key launches
## the existing ScenarioLoader / scenario screen for the configured phase.
##

@export var npc_name: String = "Stranger"
@export var scenario_phase: String = "volunteer"

const TALK_RADIUS := 70.0

var player_in_range := false
var prompt: Label

func _ready() -> void:
	# Talk-zone circle
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = TALK_RADIUS
	col.shape = shape
	add_child(col)

	# Body sprite — simple stationary figure in a contrasting colour.
	var shadow := _make_ellipse(Vector2(0, 6), Vector2(36, 12), Color(0, 0, 0, 0.3))
	add_child(shadow)
	var body := ColorRect.new()
	body.color = Palette.OLIVE_DEEP
	body.size = Vector2(24, 36)
	body.position = Vector2(-12, -30)
	add_child(body)
	var head := ColorRect.new()
	head.color = Color("D6B188")
	head.size = Vector2(18, 18)
	head.position = Vector2(-9, -48)
	add_child(head)

	# Name tag floating above the NPC.
	var tag := Label.new()
	tag.text = npc_name
	tag.add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
	tag.add_theme_font_size_override("font_size", 14)
	tag.position = Vector2(-60, -76)
	tag.size = Vector2(120, 16)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(tag)

	# Interaction prompt (hidden until player is in range).
	prompt = Label.new()
	prompt.text = "[ E ]  Talk"
	prompt.add_theme_color_override("font_color", Palette.TERRACOTTA)
	prompt.add_theme_font_size_override("font_size", 16)
	prompt.position = Vector2(-40, -96)
	prompt.size = Vector2(80, 18)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.visible = false
	add_child(prompt)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		prompt.visible = false

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		_open_scenario()

func _open_scenario() -> void:
	var s = ScenarioLoader.pick_next_for_phase(scenario_phase)
	if s == null:
		return
	get_tree().set_meta("pending_scenario", s)
	get_tree().set_meta("return_scene", "res://scenes/ward.tscn")
	get_tree().change_scene_to_file("res://scenes/scenario.tscn")

func _make_ellipse(center: Vector2, half_size: Vector2, color: Color) -> Polygon2D:
	var pts := PackedVector2Array()
	var steps := 20
	for i in range(steps):
		var a := i * TAU / steps
		pts.append(center + Vector2(cos(a) * half_size.x, sin(a) * half_size.y))
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = color
	return poly

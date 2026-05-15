extends Area2D
##
## Reusable doorway. When the player overlaps the door's circular zone a
## floating "[ E ] Enter" prompt appears; pressing the interact key warps
## to `target_scene` and tells the destination scene to spawn the player
## at the marker named `target_marker` (via tree metadata).
##

@export var target_scene: String = ""
@export var target_marker: String = "DoorIn"
@export var return_scene: String = "res://scenes/ward.tscn"

var player_in_range := false
var prompt: Label

func _ready() -> void:
	# Visible doorway marker so the player can find the door from a distance.
	# A coloured arch over a darker base reads as a building entrance even
	# without proper art.
	var base := ColorRect.new()
	base.color = Color(0.24, 0.16, 0.10)
	base.size = Vector2(48, 12)
	base.position = Vector2(-24, -6)
	add_child(base)
	var arch := Polygon2D.new()
	arch.color = Palette.TERRACOTTA
	arch.polygon = PackedVector2Array([
		Vector2(-22, -6),
		Vector2(-22, -30),
		Vector2(-12, -42),
		Vector2(12, -42),
		Vector2(22, -30),
		Vector2(22, -6),
	])
	add_child(arch)
	var sign_label := Label.new()
	sign_label.text = signage_text()
	sign_label.add_theme_color_override("font_color", Palette.TEXT_INVERSE)
	sign_label.add_theme_font_size_override("font_size", 12)
	sign_label.position = Vector2(-60, -62)
	sign_label.size = Vector2(120, 14)
	sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sign_label)

	# Interaction prompt (hidden until player is in range).
	prompt = Label.new()
	prompt.text = "[ E ]  Enter"
	prompt.add_theme_color_override("font_color", Palette.TERRACOTTA)
	prompt.add_theme_font_size_override("font_size", 16)
	prompt.position = Vector2(-40, -96)
	prompt.size = Vector2(80, 18)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.visible = false
	add_child(prompt)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func signage_text() -> String:
	# A short label derived from the target scene filename: "house" → House,
	# "office" → Panchayat Office, "ward" → Back to Ward.
	var t := target_scene.to_lower()
	if t.find("house_interior") != -1: return "House"
	if t.find("office_interior") != -1: return "Panchayat Office"
	if t.find("ward") != -1: return "Back to Ward"
	return "Door"

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
		_warp()

func _warp() -> void:
	if target_scene == "":
		return
	get_tree().set_meta("return_scene", return_scene)
	get_tree().set_meta("spawn_marker", target_marker)
	get_tree().change_scene_to_file(target_scene)

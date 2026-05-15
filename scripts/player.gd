extends CharacterBody2D
##
## Top-down isometric player. WASD / arrows move the character along the
## diamond axes so up = up-right in screen space, etc. A visible sprite is
## drawn in code (no character art shipped yet — placeholder figure).
##

const SPEED := 220.0

# Cartesian input is rotated into iso space by squashing the Y axis to
# half its length, mirroring the projection used by the world.
const ISO_RATIO := Vector2(1.0, 0.5)

var sprite_root: Node2D
var facing := Vector2(0, 1)

func _ready() -> void:
	_build_sprite()
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir.length() > 0.01:
		dir = dir.normalized()
		facing = dir
	# Project cartesian input into isometric world directions so pressing
	# Up moves up-right along the diamond's axis, not straight up.
	var world_dir := Vector2(dir.x - dir.y, (dir.x + dir.y) * 0.5)
	if world_dir.length() > 0.01:
		world_dir = world_dir.normalized()
	velocity = world_dir * SPEED
	move_and_slide()
	# Y-sort: the player should render in front of tiles whose grid row
	# is "behind" them. z_index follows the screen-y so painters' order
	# matches depth.
	z_index = int(position.y / 8) + 1000

func _build_sprite() -> void:
	sprite_root = Node2D.new()
	add_child(sprite_root)

	# Placeholder figure scaled to read against 132x101 isometric tiles.
	var shadow := _make_ellipse(Vector2(0, 8), Vector2(48, 18), Color(0, 0, 0, 0.4))
	sprite_root.add_child(shadow)

	var body := ColorRect.new()
	body.color = Palette.TERRACOTTA
	body.size = Vector2(40, 56)
	body.position = Vector2(-20, -50)
	sprite_root.add_child(body)

	var head := ColorRect.new()
	head.color = Color("E6C9A3")
	head.size = Vector2(30, 30)
	head.position = Vector2(-15, -80)
	sprite_root.add_child(head)

	var sash := ColorRect.new()
	sash.color = Palette.SAFFRON
	sash.size = Vector2(40, 9)
	sash.position = Vector2(-20, -22)
	sprite_root.add_child(sash)

	# White outline ring around the head so the player reads against any
	# tile colour (the muted Kenney palette has lots of tans).
	var outline := ColorRect.new()
	outline.color = Color(0, 0, 0, 0.6)
	outline.size = Vector2(32, 2)
	outline.position = Vector2(-16, -82)
	sprite_root.add_child(outline)

# Quick ellipse drawn via a Polygon2D — Godot has no built-in primitive.
func _make_ellipse(center: Vector2, half_size: Vector2, color: Color) -> Polygon2D:
	var pts := PackedVector2Array()
	var steps := 24
	for i in range(steps):
		var a := i * TAU / steps
		pts.append(center + Vector2(cos(a) * half_size.x, sin(a) * half_size.y))
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = color
	return poly

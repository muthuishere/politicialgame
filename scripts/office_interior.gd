extends Node2D
##
## Aryavarta Panchayat / municipal office interior.
##
## A 10x8 isometric room rendered with the same Kenney city tile pack the
## ward uses. The room is bounded by StaticBody2D walls so the player can't
## walk off the floor. A row of "desks" sits near the back wall; one of them
## hosts Ramesh the clerk, while Mr. Mishra waits near the door.
##
## Same conventions as ward.gd: tiles are Sprite2Ds parented to a y_sort_enabled
## World node, NPCs / player parented to Entities, painters' z_index = gx+gy.
##

const GRID_W := 10
const GRID_H := 8

# Reuse the ward's tile palette — flat block tiles read as office furniture
# at this zoom level and keep the spike art consistent.
const T_FLOOR := "res://assets/kenney_iso/tiles/cityTiles_090.png"      # plain ground = office floor
const T_WALL := "res://assets/kenney_iso/tiles/cityTiles_120.png"       # tall building tile = wall slab
const T_WALL_CORNER := "res://assets/kenney_iso/tiles/cityTiles_115.png" # stepped block = corner / break
const T_DESK := "res://assets/kenney_iso/tiles/cityTiles_080.png"       # flat block = desk
const T_FILE_CABINET := "res://assets/kenney_iso/tiles/cityTiles_100.png" # block with antenna = filing cabinet

@onready var world: Node2D = $World
@onready var entities: Node2D = $Entities

func _ready() -> void:
	_paint_floor()
	_paint_walls()
	_paint_desks()
	_position_npcs()
	_place_exit_door()
	_position_player()

func _paint_floor() -> void:
	for gx in range(GRID_W):
		for gy in range(GRID_H):
			_place_tile(T_FLOOR, Vector2(gx, gy), 0)

func _paint_walls() -> void:
	# Perimeter walls: back two edges (gx=0 row, gy=0 row) get tall walls.
	# Front two edges (gx=GRID_W-1, gy=GRID_H-1) are left open visually but
	# still get collision so the player can't fall off — except for the
	# door gap on the front wall.
	for gy in range(GRID_H):
		_place_tile(T_WALL, Vector2(0, gy), 0)
		_add_wall_collider(Vector2(0, gy))
	for gx in range(1, GRID_W):
		_place_tile(T_WALL, Vector2(gx, 0), 0)
		_add_wall_collider(Vector2(gx, 0))
	# Front-right wall (gx == GRID_W-1), with a door gap at gy = GRID_H-2.
	for gy in range(1, GRID_H):
		if gy == GRID_H - 2:
			continue  # door gap
		_place_tile(T_WALL_CORNER, Vector2(GRID_W - 1, gy), 0)
		_add_wall_collider(Vector2(GRID_W - 1, gy))
	# Front-left wall (gy == GRID_H-1).
	for gx in range(1, GRID_W - 1):
		_place_tile(T_WALL_CORNER, Vector2(gx, GRID_H - 1), 0)
		_add_wall_collider(Vector2(gx, GRID_H - 1))

func _paint_desks() -> void:
	# Row of desks two tiles in from the back wall. Filing cabinets in the
	# corners give the room some vertical break.
	for gy in range(2, GRID_H - 2):
		_place_tile(T_DESK, Vector2(2, gy), 0)
	# A couple of filing cabinets along the side.
	_place_tile(T_FILE_CABINET, Vector2(2, 1), 0)
	_place_tile(T_FILE_CABINET, Vector2(GRID_W - 2, 1), 0)

func _place_tile(path: String, grid: Vector2, y_offset: int) -> void:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = true
	s.position = Iso.grid_to_screen(grid) + Vector2(0, y_offset)
	s.z_index = int(grid.x + grid.y)
	world.add_child(s)

func _add_wall_collider(grid: Vector2) -> void:
	# A small static body per wall tile so the player physically bumps
	# the perimeter. CircleShape2D keeps it cheap and forgiving.
	var body := StaticBody2D.new()
	body.position = Iso.grid_to_screen(grid)
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 36.0
	col.shape = shape
	body.add_child(col)
	world.add_child(body)

func _position_player() -> void:
	# Fallback only — door warp handled by player.gd via spawn_marker meta.
	var player: Node2D = $Player
	if player.position != Vector2.ZERO:
		return
	player.position = Iso.grid_to_screen(Vector2(GRID_W - 3, GRID_H - 3))

func _place_exit_door() -> void:
	var door := preload("res://scenes/door.tscn").instantiate()
	door.target_scene = "res://scenes/ward.tscn"
	door.target_marker = "OfficeReturn"
	door.return_scene = "res://scenes/office_interior.tscn"
	# Match the DoorOut Marker2D position the .tscn declares (grid 9,6).
	door.position = Iso.grid_to_screen(Vector2(GRID_W - 1, GRID_H - 2))
	entities.add_child(door)

func _position_npcs() -> void:
	# Ramesh sits at a back-row desk; Mr. Mishra hangs out near the door.
	var npcs := [
		{"name": "Ramesh the clerk", "grid": Vector2(3, 3), "phase": "volunteer"},
		{"name": "Mr. Mishra", "grid": Vector2(GRID_W - 3, GRID_H - 4), "phase": "volunteer"},
	]
	for n in npcs:
		var npc := preload("res://scenes/npc.tscn").instantiate()
		npc.npc_name = n["name"]
		npc.scenario_phase = n["phase"]
		npc.position = Iso.grid_to_screen(n["grid"])
		entities.add_child(npc)

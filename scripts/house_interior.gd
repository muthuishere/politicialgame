extends Node2D
##
## Player's house interior — a small indoor room rendered with the same
## isometric Kenney tiles used outside. The perimeter is walled with
## StaticBody2D collisions so the player can't walk off the floor, and a
## family-member NPC stands inside to trigger the volunteer scenarios.
##
## The door agent will look up the `DoorOut` Marker2D in `Entities` to
## warp the player back to the ward — we only place the marker here.
##

const GRID_W := 8
const GRID_H := 8

# Reuse the Kenney pack: a flat park tile reads cleanly as an indoor
# floor, and the chunky blocks stand in for walls / furniture until we
# get a proper interior set.
const T_FLOOR := "res://assets/kenney_iso/tiles/cityTiles_065.png"     # flat courtyard / floor
const T_WALL := "res://assets/kenney_iso/tiles/cityTiles_080.png"      # flat block — wall segment
const T_ALMIRAH := "res://assets/kenney_iso/tiles/cityTiles_120.png"   # tall block — cabinet
const T_SHRINE := "res://assets/kenney_iso/tiles/cityTiles_115.png"    # stepped block — shrine / table
const T_RADIO := "res://assets/kenney_iso/tiles/cityTiles_100.png"     # block w/ antenna — radio set

# Wall collision is a thin rectangle straddling the diamond of one tile;
# good enough to fence the player along the perimeter.
const WALL_COLLIDER_SIZE := Vector2(132, 66)

@onready var world: Node2D = $World
@onready var entities: Node2D = $Entities

func _ready() -> void:
	_paint_floor()
	_paint_walls()
	_paint_furniture()
	_spawn_family_npc()
	_place_door_marker()
	_place_exit_door()
	_position_player()

func _paint_floor() -> void:
	for gx in range(1, GRID_W - 1):
		for gy in range(1, GRID_H - 1):
			_place_tile(T_FLOOR, Vector2(gx, gy))

func _paint_walls() -> void:
	# Perimeter ring of wall blocks. Each wall tile also drops a
	# StaticBody2D so the player physically bounces off the edge.
	for gx in range(GRID_W):
		_place_wall(Vector2(gx, 0))
		_place_wall(Vector2(gx, GRID_H - 1))
	for gy in range(1, GRID_H - 1):
		_place_wall(Vector2(0, gy))
		_place_wall(Vector2(GRID_W - 1, gy))

func _paint_furniture() -> void:
	# A few decorative props inside the room — kept off the centre so the
	# player has space to walk and reach the NPC and the door.
	_place_tile(T_ALMIRAH, Vector2(1, 1))
	_place_tile(T_SHRINE, Vector2(GRID_W - 2, 1))
	_place_tile(T_RADIO, Vector2(1, GRID_H - 2))

func _place_tile(path: String, grid: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = true
	s.position = Iso.grid_to_screen(grid)
	s.z_index = int(grid.x + grid.y)
	world.add_child(s)

func _place_wall(grid: Vector2) -> void:
	_place_tile(T_WALL, grid)
	# Static collider so the player can't escape through walls.
	var body := StaticBody2D.new()
	body.position = Iso.grid_to_screen(grid)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = WALL_COLLIDER_SIZE
	col.shape = shape
	body.add_child(col)
	world.add_child(body)

func _position_player() -> void:
	# Fallback only — if the marker-based warp in player.gd already moved
	# them (door entry), leave them where they are.
	var player: Node2D = $Player
	if player.position != Vector2.ZERO:
		return
	player.position = Iso.grid_to_screen(Vector2(GRID_W * 0.5, GRID_H - 2))

func _spawn_family_npc() -> void:
	var npc := preload("res://scenes/npc.tscn").instantiate()
	npc.npc_name = "Your mother"
	npc.scenario_phase = "volunteer"
	npc.position = Iso.grid_to_screen(Vector2(GRID_W * 0.5 - 1, 2))
	entities.add_child(npc)

func _place_door_marker() -> void:
	# DoorIn is declared statically in house_interior.tscn so it exists
	# before player.gd's _ready runs. We still need a DoorOut marker as a
	# spatial anchor for the exit door (added at runtime is fine — only the
	# arriving-spawn marker has the timing constraint).
	var door_out := Marker2D.new()
	door_out.name = "DoorOut"
	door_out.position = Iso.grid_to_screen(Vector2(GRID_W * 0.5, GRID_H - 1))
	entities.add_child(door_out)

func _place_exit_door() -> void:
	# Area2D the player can step into to warp back to the ward right next
	# to the matching HouseReturn marker.
	var door := preload("res://scenes/door.tscn").instantiate()
	door.target_scene = "res://scenes/ward.tscn"
	door.target_marker = "HouseReturn"
	door.return_scene = "res://scenes/house_interior.tscn"
	door.position = Iso.grid_to_screen(Vector2(GRID_W * 0.5, GRID_H - 1))
	entities.add_child(door)

extends Node2D
##
## Walkable isometric ward — the player's neighbourhood in Aryavarta.
##
## Tiles are placed programmatically as Sprite2D nodes ordered by their
## (gx+gy) sum so painters' algorithm renders back-to-front naturally.
## The player and NPCs sit in the same Y-sorted parent so they occlude
## correctly with the world.
##

const GRID_W := 14
const GRID_H := 14

# Kenney isometric tile filename palette. The pack ships flat ground +
# road + decorative blocks; we use the chunky block tiles as stand-ins
# for buildings until we get a proper residential pack.
const T_GROUND := "res://assets/kenney_iso/tiles/cityTiles_090.png"   # plain sand
const T_ROAD := "res://assets/kenney_iso/tiles/cityTiles_010.png"     # paved road slice
const T_HOUSE_SMALL := "res://assets/kenney_iso/tiles/cityTiles_080.png" # flat block
const T_HOUSE := "res://assets/kenney_iso/tiles/cityTiles_115.png"    # stepped roof building
const T_HOUSE_TALL := "res://assets/kenney_iso/tiles/cityTiles_120.png" # tall building
const T_PARK := "res://assets/kenney_iso/tiles/cityTiles_065.png"     # park / courtyard
const T_TREE_TILE := "res://assets/kenney_iso/tiles/cityTiles_100.png" # block with antenna

@onready var world: Node2D = $World
@onready var entities: Node2D = $Entities
@onready var camera: Camera2D = $Player/Camera2D

func _ready() -> void:
	_paint_ground()
	_paint_roads()
	_paint_buildings()
	_place_doors()
	_position_player()
	_position_npcs()

func _paint_ground() -> void:
	# Plain sand fills the grid. Tiles draw back-to-front via z_index.
	for gx in range(GRID_W):
		for gy in range(GRID_H):
			_place_tile(T_GROUND, Vector2(gx, gy), 0)

func _paint_roads() -> void:
	# A cross of paved road through the middle of the ward.
	var mid_x := GRID_W / 2
	var mid_y := GRID_H / 2
	for gy in range(GRID_H):
		_place_tile(T_ROAD, Vector2(mid_x, gy), 0)
	for gx in range(GRID_W):
		_place_tile(T_ROAD, Vector2(gx, mid_y), 0)

func _paint_buildings() -> void:
	# Buildings on each of the four quadrants off the central crossroad.
	# (gx, gy, kind) tuples — kind picks one of three building heights.
	var blocks := [
		[Vector2(2, 2), T_HOUSE], [Vector2(4, 2), T_HOUSE_TALL],
		[Vector2(2, 4), T_HOUSE_SMALL],
		[Vector2(10, 2), T_HOUSE], [Vector2(12, 4), T_HOUSE_SMALL],
		[Vector2(2, 10), T_HOUSE_TALL], [Vector2(4, 12), T_HOUSE],
		[Vector2(10, 10), T_HOUSE_SMALL], [Vector2(12, 12), T_HOUSE],
	]
	for b in blocks:
		_place_tile(b[1], b[0], 0)
	# A couple of parks / open spaces.
	for p in [Vector2(11, 11), Vector2(3, 3)]:
		_place_tile(T_PARK, p, 0)

func _place_tile(path: String, grid: Vector2, y_offset: int) -> void:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = true
	# The PNGs are 132x101 with the diamond top centred in the upper half.
	# Anchor on the diamond's centre so grid_to_screen lands tiles cleanly.
	s.position = Iso.grid_to_screen(grid) + Vector2(0, y_offset)
	# Y-sort by world-y so tiles with higher gx+gy draw on top.
	s.z_index = int(grid.x + grid.y)
	world.add_child(s)

func _position_player() -> void:
	# Fallback spawn for a fresh load. If the player arrived through a door
	# (player.gd already moved them to a marker), leave them where they are.
	var player: Node2D = $Player
	if player.position != Vector2.ZERO:
		return
	player.position = Iso.grid_to_screen(Vector2(GRID_W * 0.5, GRID_H * 0.5 + 1))

func _place_doors() -> void:
	# Entry doors into the two interior scenes. The matching return markers
	# (HouseReturn, OfficeReturn) are declared statically in ward.tscn so
	# they exist before Player._ready runs and tries to find them.
	_spawn_door(
		Vector2(2, 2),                                # next to the house cluster
		"res://scenes/house_interior.tscn",
		"DoorIn",
	)
	_spawn_door(
		Vector2(10, 2),                               # near the office cluster
		"res://scenes/office_interior.tscn",
		"DoorIn",
	)

func _spawn_door(grid: Vector2, target_scene: String, target_marker: String) -> void:
	var door := preload("res://scenes/door.tscn").instantiate()
	door.target_scene = target_scene
	door.target_marker = target_marker
	door.position = Iso.grid_to_screen(grid)
	entities.add_child(door)

func _position_npcs() -> void:
	# Three NPCs scattered around the ward — each wired to a phase of the
	# political-scenario backend.
	var npcs := [
		{"name": "Lakshmi-bai", "grid": Vector2(3, 3), "phase": "volunteer"},
		{"name": "Ramesh the clerk", "grid": Vector2(11, 3), "phase": "volunteer"},
		{"name": "Devi (tap fame)", "grid": Vector2(3, 11), "phase": "volunteer"},
	]
	for n in npcs:
		var npc := preload("res://scenes/npc.tscn").instantiate()
		npc.npc_name = n["name"]
		npc.scenario_phase = n["phase"]
		npc.position = Iso.grid_to_screen(n["grid"])
		entities.add_child(npc)

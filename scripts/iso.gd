extends Node
class_name Iso

# Kenney isometric city tiles are 132x101 PNGs. The visible diamond top
# of each tile is approximately 132 wide x 66 tall (the rest of the PNG
# is the 3D side faces beneath the diamond).
const TILE_W := 132
const TILE_H := 66

# Convert a grid cell (gx, gy) into pixel coordinates of the diamond's
# centre on screen. Grid (0,0) is at origin; +gx moves down-right, +gy
# moves down-left.
static func grid_to_screen(g: Vector2) -> Vector2:
	return Vector2((g.x - g.y) * TILE_W * 0.5, (g.x + g.y) * TILE_H * 0.5)

# Reverse projection: screen pixel back to fractional grid cell.
static func screen_to_grid(s: Vector2) -> Vector2:
	var gx := (s.x / (TILE_W * 0.5) + s.y / (TILE_H * 0.5)) * 0.5
	var gy := (s.y / (TILE_H * 0.5) - s.x / (TILE_W * 0.5)) * 0.5
	return Vector2(gx, gy)

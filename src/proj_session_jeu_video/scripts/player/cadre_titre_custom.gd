extends Control

const FOND := Color(0.008, 0.035, 0.033, 0.92)
const BORDURE := Color("#16866B")
const LUMIERE := Color("#43F2B0")
const ACCENT := Color("#D9B949")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var pointe := 44.0
	var contour := PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(size.x - pointe, 0.0),
		Vector2(size.x, size.y * 0.5),
		Vector2(size.x - pointe, size.y),
		Vector2(0.0, size.y),
	])
	draw_colored_polygon(contour, FOND)
	var contour_ferme := contour.duplicate()
	contour_ferme.append(contour[0])
	draw_polyline(contour_ferme, BORDURE, 2.0, true)

	var chevron := PackedVector2Array([
		Vector2(size.x - 104.0, 1.0),
		Vector2(size.x - 62.0, 1.0),
		Vector2(size.x - 18.0, size.y * 0.5),
		Vector2(size.x - 62.0, size.y - 1.0),
		Vector2(size.x - 104.0, size.y - 1.0),
		Vector2(size.x - 64.0, size.y * 0.5),
	])
	draw_colored_polygon(chevron, Color(0.025, 0.13, 0.105, 0.75))

	draw_line(Vector2(12.0, 3.0), Vector2(size.x - pointe - 8.0, 3.0), LUMIERE, 2.0, true)
	draw_line(Vector2(12.0, size.y - 3.0), Vector2(size.x - pointe - 8.0, size.y - 3.0), BORDURE, 2.0, true)
	draw_line(Vector2(0.0, size.y - 3.0), Vector2(minf(250.0, size.x * 0.28), size.y - 3.0), ACCENT, 3.0, true)
	draw_line(Vector2(size.x - 18.0, size.y * 0.5), Vector2(size.x - 56.0, 1.0), LUMIERE, 1.5, true)

extends Node2D

@export var avant_personnage := false

const CENTRE := Vector2(161.5, 364.0)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if avant_personnage:
		_dessiner_bord_avant()
		return

	draw_colored_polygon(
		_points_ellipse(CENTRE + Vector2(0.0, 2.0), Vector2(138.0, 18.0)),
		Color("#031B19")
	)
	draw_colored_polygon(
		_points_ellipse(CENTRE + Vector2(0.0, -2.0), Vector2(104.0, 10.0)),
		Color("#0A382F")
	)
	_dessiner_ellipse_arc(CENTRE, Vector2(138.0, 18.0), PI, TAU, Color("#14745F"), 3.0)
	_dessiner_ellipse_arc(CENTRE, Vector2(120.0, 14.0), PI, TAU, Color(0.0, 0.94, 0.59, 0.55), 5.0)
	_dessiner_ellipse_arc(CENTRE, Vector2(120.0, 14.0), PI, TAU, Color("#13E8A0"), 2.0)
	_dessiner_ellipse(CENTRE + Vector2(0.0, 9.0), Vector2(56.0, 6.0), Color(0.0, 0.0, 0.0, 0.62), 2.0)

	for cote in [-1.0, 1.0]:
		var origine := CENTRE + Vector2(cote * 128.0, 0.0)
		draw_line(origine, origine + Vector2(cote * 7.0, -6.0), Color("#50FFC4"), 2.0)
		draw_circle(origine + Vector2(cote * 8.0, -7.0), 2.0, Color("#C7FFEA"))


func _dessiner_bord_avant() -> void:
	_dessiner_ellipse_arc(CENTRE, Vector2(138.0, 18.0), 0.0, PI, Color("#20D99D"), 3.0)
	_dessiner_ellipse_arc(CENTRE, Vector2(120.0, 14.0), 0.0, PI, Color(0.0, 0.94, 0.59, 0.4), 8.0)
	_dessiner_ellipse_arc(CENTRE, Vector2(120.0, 14.0), 0.0, PI, Color("#48FFC0"), 2.0)


func _dessiner_ellipse(centre: Vector2, rayons: Vector2, couleur: Color, largeur: float) -> void:
	draw_polyline(_points_ellipse(centre, rayons), couleur, largeur, true)


func _dessiner_ellipse_arc(
	centre: Vector2, rayons: Vector2, debut: float, fin: float, couleur: Color, largeur: float
) -> void:
	var points := PackedVector2Array()
	for index in range(33):
		var angle := lerpf(debut, fin, float(index) / 32.0)
		points.append(centre + Vector2(cos(angle) * rayons.x, sin(angle) * rayons.y))
	draw_polyline(points, couleur, largeur, true)


func _points_ellipse(centre: Vector2, rayons: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(65):
		var angle := TAU * float(index) / 64.0
		points.append(centre + Vector2(cos(angle) * rayons.x, sin(angle) * rayons.y))
	return points

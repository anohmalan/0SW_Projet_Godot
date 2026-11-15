class_name CoeursHUD
extends Control

## Rangée de cœurs du HUD : pleins pour les chances restantes, en contour pour les perdues.

const COULEUR_PLEIN := Color("#FF3355")
const COULEUR_VIDE := Color(1.0, 0.2, 0.33, 0.35)
const COULEUR_CONTOUR := Color("#073A32")

@export var taille_coeur := 22.0
@export var espacement := 6.0

var _coeurs := 3
var _coeurs_max := 3
var _forme := PackedVector2Array()
var _pulsation := 0.0 # 1 juste après la perte d'un cœur, puis s'estompe


func _ready() -> void:
	_forme = _construire_forme()
	_mettre_a_jour_taille()


func definir(coeurs: int, coeurs_max: int) -> void:
	if coeurs < _coeurs:
		_pulsation = 1.0
		set_process(true)
	_coeurs = coeurs
	_coeurs_max = coeurs_max
	_mettre_a_jour_taille()
	queue_redraw()


func _process(delta: float) -> void:
	_pulsation = move_toward(_pulsation, 0.0, delta * 2.0)
	queue_redraw()
	if _pulsation <= 0.0:
		set_process(false)


func _draw() -> void:
	for i in _coeurs_max:
		var centre := Vector2(taille_coeur * 0.5 + i * (taille_coeur + espacement), size.y * 0.5)
		var plein := i < _coeurs
		var echelle := taille_coeur
		# Le cœur qui vient d'être perdu grossit un instant avant de s'éteindre.
		if i == _coeurs and _pulsation > 0.0:
			echelle *= 1.0 + 0.4 * _pulsation
		var points := _forme_a(centre, echelle)
		if plein:
			draw_colored_polygon(points, COULEUR_PLEIN)
		else:
			draw_colored_polygon(points, COULEUR_VIDE)
		draw_polyline(points + PackedVector2Array([points[0]]), COULEUR_CONTOUR if plein else COULEUR_PLEIN, 2.0, true)


func _forme_a(centre: Vector2, echelle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for p in _forme:
		points.append(centre + p * echelle)
	return points


## Courbe de cœur classique, normalisée sur environ 1 × 1.
static func _construire_forme() -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := 32
	for k in segments:
		var t := TAU * k / segments
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(Vector2(x, y + 2.0) / 34.0)
	return points


func _mettre_a_jour_taille() -> void:
	custom_minimum_size = Vector2(_coeurs_max * taille_coeur + (_coeurs_max - 1) * espacement, taille_coeur + 4.0)

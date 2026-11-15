class_name EffetReapparition
extends Node2D

## Effet ponctuel au point de réapparition : colonne de lumière et anneau qui s'élargit,
## puis disparition. Créé par Player.reapparaitre().

const COULEUR := Color("#00D995")

@export var duree := 0.8
@export var hauteur_colonne := 150.0
@export var rayon_max := 90.0

var _temps := 0.0


func _ready() -> void:
	z_index = 1


func _process(delta: float) -> void:
	_temps += delta
	if _temps >= duree:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _temps / duree           # 0 → 1
	var force := 1.0 - t               # s'estompe
	var centre := Vector2(0.0, -hauteur_colonne * 0.4)

	# Colonne de lumière qui s'amincit.
	var largeur := lerpf(46.0, 6.0, t)
	var colonne := COULEUR
	colonne.a = 0.35 * force
	draw_rect(Rect2(-largeur * 0.5, -hauteur_colonne, largeur, hauteur_colonne), colonne)
	var coeur := Color(1, 1, 1, 0.5 * force)
	draw_rect(Rect2(-largeur * 0.15, -hauteur_colonne, largeur * 0.3, hauteur_colonne), coeur)

	# Anneau qui s'élargit, et halo au centre.
	var anneau := COULEUR
	anneau.a = 0.9 * force
	draw_arc(centre, lerpf(10.0, rayon_max, ease(t, 0.4)), 0.0, TAU, 48, anneau, 3.0, true)
	var halo := COULEUR
	halo.a = 0.25 * force
	draw_circle(centre, lerpf(50.0, 20.0, t), halo)

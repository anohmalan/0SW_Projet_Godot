class_name BarreVieEnnemi
extends Node2D

## Petite jauge au-dessus de l'ennemi, visible seulement après un coup.

@export var largeur := 40.0
@export var hauteur := 5.0
@export var duree_affichage := 2.5
@export var duree_fondu := 0.4
## Vitesse (fraction de jauge par seconde) à laquelle la bande blanche rattrape la vie.
@export var vitesse_rattrapage := 0.8

const COULEUR_PLEINE := Color(0.2, 1.0, 0.6)
const COULEUR_VIDE := Color(1.0, 0.2, 0.3)

var _ratio := 1.0
var _ratio_retarde := 1.0
var _temps_restant := 0.0


func _ready() -> void:
	cacher()


func afficher(vie: int, vie_max: int) -> void:
	_ratio = clampf(float(vie) / float(vie_max), 0.0, 1.0)
	_temps_restant = duree_affichage
	modulate.a = 1.0
	set_process(true)
	queue_redraw()


func cacher() -> void:
	modulate.a = 0.0
	set_process(false)


func _process(delta: float) -> void:
	_ratio_retarde = move_toward(_ratio_retarde, _ratio, vitesse_rattrapage * delta)
	_temps_restant -= delta
	if _temps_restant < duree_fondu:
		modulate.a = maxf(_temps_restant / duree_fondu, 0.0)
	if _temps_restant <= 0.0:
		_ratio_retarde = _ratio
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var origine := Vector2(-largeur * 0.5, 0.0)
	draw_rect(Rect2(origine - Vector2.ONE, Vector2(largeur + 2.0, hauteur + 2.0)), Color(0.0, 0.0, 0.0, 0.7))
	draw_rect(Rect2(origine, Vector2(largeur * _ratio_retarde, hauteur)), Color(1.0, 1.0, 1.0, 0.85))
	draw_rect(Rect2(origine, Vector2(largeur * _ratio, hauteur)), COULEUR_VIDE.lerp(COULEUR_PLEINE, _ratio))

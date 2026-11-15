class_name OrbeEnnemi
extends Balle

## Projectile de l'ennemi : une orbe pulsante avec une traînée, plus lente et lisible qu'une balle.

const RAYON := 6.0
const LONGUEUR_TRAINEE := 22.0

var _pulsation := 0.0


func _physics_process(delta: float) -> void:
	super(delta)
	_pulsation += delta * 18.0
	queue_redraw()


func _draw() -> void:
	var halo := 1.0 + sin(_pulsation) * 0.15
	# Traînée : cercles de plus en plus petits et transparents derrière l'orbe.
	for i in 4:
		var t := float(i + 1) / 4.0
		var couleur := _couleur
		couleur.a = 0.35 * (1.0 - t)
		draw_circle(Vector2(-LONGUEUR_TRAINEE * t, 0.0), RAYON * (1.0 - t * 0.6), couleur)
	var lueur := _couleur
	lueur.a = 0.3
	draw_circle(Vector2.ZERO, RAYON * 1.9 * halo, lueur)
	draw_circle(Vector2.ZERO, RAYON, _couleur)
	draw_circle(Vector2.ZERO, RAYON * 0.45, Color(1.0, 0.95, 0.95))

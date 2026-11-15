class_name Drapeau
extends Area2D

## Drapeau de fin de niveau : le joueur qui le touche termine le niveau.
## Placé n'importe où au-dessus du sol, il s'y pose tout seul au démarrage.

signal atteint

const COULEUR := Color("#3FE0FF")
const COULEUR_ATTEINT := Color("#FFD23F")

@export var hauteur_mat := 130.0
@export var largeur_tissu := 52.0
@export var hauteur_tissu := 34.0

var _temps := 0.0
var _atteint := false


func _ready() -> void:
	add_to_group(&"drapeau") # repéré par la mini-carte
	body_entered.connect(_sur_entree)
	_poser_au_sol.call_deferred()


func _process(delta: float) -> void:
	_temps += delta
	queue_redraw()


## Descend le drapeau jusqu'au premier sol (couche « monde ») situé dessous.
func _poser_au_sol() -> void:
	var requete := PhysicsRayQueryParameters2D.create(
		global_position, global_position + Vector2(0.0, 3000.0), 1)
	var impact := get_world_2d().direct_space_state.intersect_ray(requete)
	if not impact.is_empty():
		global_position = impact["position"]


func _sur_entree(corps: Node2D) -> void:
	var player := corps as Player
	if _atteint or player == null or player.state_machine.current_state is PlayerDead:
		return
	_atteint = true
	atteint.emit()


func _draw() -> void:
	var couleur := COULEUR_ATTEINT if _atteint else COULEUR
	# Halo pulsant, pour repérer le drapeau de loin.
	var halo := couleur
	halo.a = 0.10 + 0.05 * sin(_temps * 3.0)
	draw_circle(Vector2(0.0, -hauteur_mat * 0.55), 60.0 + 6.0 * sin(_temps * 3.0), halo)
	# Socle et mât.
	draw_rect(Rect2(-12.0, -5.0, 24.0, 5.0), Color(0.12, 0.2, 0.19))
	draw_line(Vector2.ZERO, Vector2(0.0, -hauteur_mat), Color(0.85, 0.92, 0.9), 4.0)
	draw_circle(Vector2(0.0, -hauteur_mat), 4.0, couleur)
	# Tissu qui ondule : l'amplitude augmente vers le bout libre.
	var haut := PackedVector2Array()
	var bas := PackedVector2Array()
	var segments := 10
	for i in segments + 1:
		var t := float(i) / segments
		var vague := sin(_temps * 6.0 - t * 5.0) * 4.0 * t
		var x := 2.0 + t * largeur_tissu
		haut.append(Vector2(x, -hauteur_mat + vague))
		bas.append(Vector2(x, -hauteur_mat + hauteur_tissu * (1.0 - 0.15 * t) + vague))
	bas.reverse()
	draw_colored_polygon(haut + bas, couleur)
	draw_polyline(haut + bas + PackedVector2Array([haut[0]]), Color(1, 1, 1, 0.7), 1.5)

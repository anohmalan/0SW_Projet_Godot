class_name PlateformeMobile
extends AnimatableBody2D

## Plateforme qui fait l'aller-retour entre sa position de départ et départ + trajet.
## Elle ne traverse jamais le niveau : si un élément lui barre la route, elle s'arrête
## contre lui (à la manière d'une pièce de Tetris) et repart vers l'autre position.
## Les deux positions sont fixées au démarrage, donc un demi-tour ne la fait jamais dériver.

## Déplacement jusqu'à la seconde position, dans le repère du parent.
@export var trajet := Vector2(0, 1100)
@export var vitesse := 275.0
## Temps d'arrêt à chaque extrémité ou contre un obstacle.
@export var pause := 0.4

var _positions: Array[Vector2] = []
var _index_cible := 1
var _attente := 0.0


func _ready() -> void:
	# Déplacée par move_and_collide : la synchronisation avec l'animation ne sert pas ici.
	sync_to_physics = false
	var depart := global_position
	var arrivee := depart + _vers_global(trajet)
	_positions = [depart, arrivee]


func _physics_process(delta: float) -> void:
	if _attente > 0.0:
		_attente -= delta
		return
	var ecart := _positions[_index_cible] - global_position
	var pas := vitesse * delta
	if ecart.length() <= pas:
		# Dernier bout de trajet : arrivée ou obstacle juste avant, on repart dans les deux cas.
		move_and_collide(ecart)
		_repartir()
		return
	if move_and_collide(ecart.normalized() * pas) != null:
		_repartir()


## Prend l'autre position comme cible, après une courte pause.
func _repartir() -> void:
	_index_cible = 1 - _index_cible
	_attente = pause


## Convertit un déplacement exprimé dans le repère du parent (ex. monde agrandi ×1,1).
func _vers_global(deplacement: Vector2) -> Vector2:
	var parent := get_parent() as Node2D
	return parent.global_transform.basis_xform(deplacement) if parent != null else deplacement

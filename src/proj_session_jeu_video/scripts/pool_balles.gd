class_name PoolBalles
extends Node

@export var scene_balle: PackedScene
@export var taille := 64

var _balles: Array[Balle] = []
var _suivant := 0


func _ready() -> void:
	for i in taille:
		var b: Balle = scene_balle.instantiate()
		add_child(b)
		_balles.append(b)


func tirer(pos: Vector2, dir: Vector2, arme: Arme, du_joueur: bool) -> void:
	for i in _balles.size():
		var idx := (_suivant + i) % _balles.size()
		if not _balles[idx].actif:
			_suivant = (idx + 1) % _balles.size()
			_balles[idx].activer(pos, dir, arme, du_joueur)
			return
	# Aucune balle libre : le tir est ignoré (peu probable avec 64 balles).


# Pour l'affichage F12 plus tard.
func nombre_actives() -> int:
	var n := 0
	for b in _balles:
		if b.actif:
			n += 1
	return n
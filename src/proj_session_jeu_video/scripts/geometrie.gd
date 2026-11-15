class_name Geometrie
extends RefCounted

# Vrai si b est à moins de « portee » pixels de a (sans racine carrée, plus rapide).
static func dans_portee(a: Vector2, b: Vector2, portee: float) -> bool:
	return a.distance_squared_to(b) <= portee * portee


## Descend un objet jusqu'au premier sol (couche « monde » par défaut) situé sous lui.
## Laisse l'objet en place s'il n'y a pas de sol dessous.
static func poser_au_sol(noeud: Node2D, masque: int = 1, distance_max: float = 3000.0) -> void:
	var requete := PhysicsRayQueryParameters2D.create(
		noeud.global_position, noeud.global_position + Vector2(0.0, distance_max), masque)
	var impact := noeud.get_world_2d().direct_space_state.intersect_ray(requete)
	if not impact.is_empty():
		noeud.global_position = impact["position"]
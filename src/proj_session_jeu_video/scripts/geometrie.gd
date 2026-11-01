class_name Geometrie
extends RefCounted

# Vrai si b est à moins de « portee » pixels de a (sans racine carrée, plus rapide).
static func dans_portee(a: Vector2, b: Vector2, portee: float) -> bool:
	return a.distance_squared_to(b) <= portee * portee
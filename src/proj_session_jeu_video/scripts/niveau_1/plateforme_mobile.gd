extends CharacterBody2D

## Position locale visée par l'AnimationPlayer.
@export var position_cible: Vector2 = Vector2.ZERO

var _position_cible_precedente := Vector2.ZERO
var _sens_mouvement := 1.0


func _physics_process(delta: float) -> void:
	# L'animation fournit le déplacement par image; la plateforme garde une vitesse fluide.
	var mouvement := (position_cible - _position_cible_precedente) * _sens_mouvement
	_position_cible_precedente = position_cible
	if mouvement.length_squared() <= 0.0001:
		velocity = Vector2.ZERO
		return

	# Un joueur déjà posé sur la plateforme est transporté avec elle, pas traité comme un obstacle.
	var masque_initial := collision_mask
	if _joueur_pose_sur_plateforme():
		collision_mask = collision_mask & 1
	velocity = mouvement / delta
	move_and_slide()
	if get_slide_collision_count() > 0:
		var collision := get_slide_collision(0)
		print("[PLATEFORME] obstacle=", collision.get_collider(),
			" position=", global_position, " cible=", position_cible)
		_sens_mouvement *= -1.0
	collision_mask = masque_initial


func _joueur_pose_sur_plateforme() -> bool:
	for noeud_joueur in get_tree().get_nodes_in_group("joueur"):
		var joueur := noeud_joueur as CharacterBody2D
		if joueur == null or not joueur.is_on_floor():
			continue
		for i in range(joueur.get_slide_collision_count()):
			var collision := joueur.get_slide_collision(i)
			if collision.get_collider() == self and collision.get_normal().dot(Vector2.UP) > 0.7:
				return true
	return false

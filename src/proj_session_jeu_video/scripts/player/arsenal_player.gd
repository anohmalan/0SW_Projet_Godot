class_name ArsenalPlayer
extends Node

var armes: Array[Arme] = []
var munitions: Array[int] = []
var index_arme := 0
var temps_depuis_tir := 99.0
var _player: Player


func initialiser(player: Player) -> void:
	_player = player
	armes = Arme.catalogue()
	for arme in armes:
		munitions.append(arme.munitions_max)
	_equiper(0)


func rafraichir() -> void:
	_player.arme_changee.emit(armes[index_arme], munitions[index_arme])


func gerer_commandes() -> bool:
	if Input.is_action_just_pressed("arme_suivante"):
		_arme_suivante()
	if Input.is_action_pressed("tir") and temps_depuis_tir >= armes[index_arme].cadence:
		# La pose de visée doit être choisie avant de calculer l'origine du tir.
		temps_depuis_tir = 0.0
		return true
	return false


func ajouter_munitions(i: int, quantite: int) -> void:
	if armes[i].munitions_max < 0:
		return
	munitions[i] = mini(munitions[i] + quantite, armes[i].munitions_max)
	if i == index_arme:
		_player.munitions_changees.emit(munitions[i])


func _equiper(i: int) -> void:
	index_arme = i
	_player.visuel.definir_carte("Gun", armes[i].carte)
	_player.visuel.position_bouche(armes[i].bouche_y)
	rafraichir()


func _arme_suivante() -> void:
	for pas in range(1, armes.size()):
		var i := (index_arme + pas) % armes.size()
		if munitions[i] != 0:
			_equiper(i)
			return


func tirer() -> void:
	var arme := armes[index_arme]
	temps_depuis_tir = 0.0
	var bouche: Vector2 = _player.visuel.position_bouche(arme.bouche_y)
	for i in arme.projectiles:
		var ecart := deg_to_rad(randf_range(-arme.dispersion, arme.dispersion))
		_player.tir_demande.emit(bouche, Vector2(_player.direction, 0.0).rotated(ecart), arme)
	if munitions[index_arme] > 0:
		munitions[index_arme] -= 1
		_player.munitions_changees.emit(munitions[index_arme])
		if munitions[index_arme] == 0:
			_arme_suivante()

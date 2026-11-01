class_name VisuelPlayerCustomization
extends RefCounted

var _donnees: SpriterAnimations
var _ordre_categories: Array
var _selection := {}
var _cartes_actives: Array = []
var _cache := {}


func initialiser(donnees: SpriterAnimations, ordre_categories: Array) -> void:
	_donnees = donnees
	_ordre_categories = ordre_categories.duplicate()


func definir_carte(categorie: String, nom_carte: String = "") -> bool:
	if nom_carte == "":
		_selection.erase(categorie)
	elif _donnees.cartes.has(nom_carte):
		_selection[categorie] = nom_carte
	else:
		push_error("Carte inconnue : " + nom_carte)
		return false
	_recalculer()
	return true


func appliquer_apparence(selection: Dictionary) -> void:
	_selection = selection.duplicate()
	_recalculer()


func variantes(categorie: String) -> Array:
	var res := []
	for nom in _donnees.cartes:
		if String(nom).begins_with(categorie + " - "):
			res.append(nom)
	return res


func cartes_actives() -> Array:
	return _cartes_actives.duplicate()


func resoudre(dossier: int, fichier: int) -> Array:
	var cle := dossier * 1000 + fichier
	if _cache.has(cle):
		return _cache[cle]
	var d := dossier
	var f := fichier
	for nom in _cartes_actives:
		for regle in _donnees.cartes[nom]:
			if regle["dossier"] == d and regle["fichier"] == f:
				if regle["cible_dossier"] == -1:
					_cache[cle] = []
					return []
				d = regle["cible_dossier"]
				f = regle["cible_fichier"]
				break
	_cache[cle] = [d, f]
	return [d, f]


func _recalculer() -> void:
	_cartes_actives.clear()
	for cat in _ordre_categories:
		if _selection.has(cat):
			_cartes_actives.append(_selection[cat])
	_cache.clear()

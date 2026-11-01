extends Node

const CHEMIN := "user://apparence_player.cfg"
const CATEGORIES := ["Head", "Balaclava", "Mask", "Googles", "Head Gear","Strap", "Shirt", "Jacket", "Pants"]

var selection: Dictionary = {}
var erreur_chargement := ""

var _donnees := SpriterAnimations.new()

func _ready() -> void:
	_donnees.charger(VisuelPlayer.CHEMIN_SCML)
	_charger()

func _charger() -> void:
	if not FileAccess.file_exists(CHEMIN):
		return
	
	var fichier := ConfigFile.new()
	var erreur := fichier.load(CHEMIN)
	if erreur != OK:
		_signaler_erreur("Lecture de l'apparence impossible : " + error_string(erreur))
		return

	var valeurs : Variant = fichier.get_value("apparence", "selection", null)
	if not valeurs is Dictionary:
		_signaler_erreur("Le fichier d'apparence ne contient pas une sélection valide.")
		return
	
	if valeurs.get("Head Gear", "") == "Head Gear - No Strap":
		valeurs.erase("Head Gear")
		valeurs["Strap"] = "Strap - No Strap"

	if not _selection_valide(valeurs):
		_signaler_erreur("Le fichier d'apparence contient des variantes inconnues.")
		return
	
	selection = valeurs.duplicate(true)

func _signaler_erreur(message: String) -> void:
	erreur_chargement = message
	push_error(message)

func _selection_valide(valeurs: Dictionary) -> bool:
	for categorie in valeurs:
		if categorie not in CATEGORIES:
			return false
		
		var carte: Variant = valeurs[categorie]
		if not carte is String:
			return false
		if not carte.begins_with(String(categorie) + " - "):
			return false
		if not _donnees.cartes.has(carte):
			return false

	return true

func enregistrer(valeurs: Dictionary) -> Error:
	if not _selection_valide(valeurs):
		push_error("Apparence invalide : catégorie ou variante inconnue.")
		return ERR_INVALID_DATA

	var fichier := ConfigFile.new()
	fichier.set_value("apparence", "selection", valeurs)

	var erreur := fichier.save(CHEMIN)
	if erreur != OK:
		push_error("Sauvegarde de l'apparence impossible : " + error_string(erreur))
		return erreur

	selection = valeurs.duplicate(true)
	erreur_chargement = ""

	return OK

class_name VisuelPlayer
extends Node2D

signal animation_terminee(nom: String)

const CHEMIN_SCML := "res://assets/sprites/sprites_joueur/Spriter.scml"
const PREFIXE_LIB_ANIM := "scml/"
const NOM_ENTITE_JOUEUR := "Char"
const ORDRE_CATEGORIES := ["Head", "Balaclava", "Mask", "Googles",
		"Head Gear", "Shirt", "Jacket", "Pants", "Gun"]
const NOMS_SPRITES_ARMES := ["AK47", "Sniper", "Shotgun (1)", "Assault Rifles (1)", "Grenade Launcher"]

const IMPORTED_ADAPTER_SCRIPT := preload("res://scripts/player/visuel_player_imported_adapter.gd")
const CUSTOMIZATION_SCRIPT := preload("res://scripts/player/visuel_player_customization.gd")

var vitesse := 1.0
var nom_animation := ""

var _loader := SpriterLoader.new()
var _donnees := SpriterAnimations.new()
var _customisation_differee_en_cours := false

var _imported_adapter = IMPORTED_ADAPTER_SCRIPT.new()
var _customization = CUSTOMIZATION_SCRIPT.new()


func _ready() -> void:
	_loader.charger_images(CHEMIN_SCML)
	_donnees.charger(CHEMIN_SCML)
	_customization.initialiser(_donnees, ORDRE_CATEGORIES)

	if not _imported_adapter.initialiser(
			self,
			CHEMIN_SCML,
			NOM_ENTITE_JOUEUR,
			PREFIXE_LIB_ANIM,
			_loader):
		push_error("VisuelPlayer requiert une scène SCML importée valide. Détail: %s" % _imported_adapter.last_error)
		return
	_imported_adapter.animation_terminee.connect(_sur_animation_finie_importee)

	jouer("Idle")


func jouer(nom: String, relancer := false, depart := 0.0) -> void:
	vitesse = 2.0 if nom.begins_with("Jump") else 1.0

	var nom_importe: String = _imported_adapter.jouer(nom, relancer, depart, vitesse, nom_animation)
	if not nom_importe.is_empty():
		nom_animation = nom_importe


func _process(delta: float) -> void:
	if not _customization.cartes_actives().is_empty():
		_programmer_customisation_importee()


func changer_variante(nom: String) -> void:
	var position_actuelle := _imported_adapter.position_animation_ms()
	jouer(nom, true, position_actuelle)


func position_bouche(bouche_y: float) -> Vector2:
	return _imported_adapter.position_bouche(bouche_y, NOMS_SPRITES_ARMES, global_position)


func definir_carte(categorie: String, nom_carte: String = "") -> void:
	if not _customization.definir_carte(categorie, nom_carte):
		return
	_appliquer_customisation()


func appliquer_apparence(selection: Dictionary) -> void:
	_customization.appliquer_apparence(selection)
	_appliquer_customisation()


func variantes(categorie: String) -> Array:
	return _customization.variantes(categorie)


func _appliquer_customisation() -> void:
	_programmer_customisation_importee()


func _resolver_customisation() -> Callable:
	return Callable(self, "_resoudre_customisation")


func _resoudre_customisation(dossier: int, fichier: int) -> Array:
	return _customization.resoudre(dossier, fichier)


func _programmer_customisation_importee() -> void:
	if _customisation_differee_en_cours:
		return
	_customisation_differee_en_cours = true
	call_deferred("_appliquer_customisation_importee")


func _appliquer_customisation_importee() -> void:
	_customisation_differee_en_cours = false
	_imported_adapter.appliquer_customisation_importee(_resolver_customisation())


func _sur_animation_finie_importee(nom: String) -> void:
	animation_terminee.emit(nom)

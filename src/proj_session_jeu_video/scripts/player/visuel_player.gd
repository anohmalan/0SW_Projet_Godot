class_name VisuelPlayer
extends Node2D

signal animation_terminee(nom: String)

const CHEMIN_SCML := "res://assets/sprites/sprites_joueur/Spriter.scml"
const PREFIXE_LIB_ANIM := "scml/"
const ORDRE_CATEGORIES := ["Head", "Balaclava", "Mask", "Googles",
	"Head Gear","Strap", "Shirt", "Jacket", "Pants", "Gun"]
const IMPORTED_ADAPTER_SCRIPT := preload("res://scripts/player/visuel_player_imported_adapter.gd")
const CUSTOMIZATION_SCRIPT := preload("res://scripts/player/visuel_player_customization.gd")
const SOURCES_MINIATURES := {
    "Head": Vector2i(0, 0),
    "Balaclava": Vector2i(1, 0),
    "Mask": Vector2i(7, 3),
    "Googles": Vector2i(3, 0),
    "Head Gear": Vector2i(5, 16),
    "Shirt": Vector2i(9, 3),
    "Jacket": Vector2i(6, 6),
    "Pants": Vector2i(8, 0),
    "Strap": Vector2i(5, 22)
}

var vitesse: float = 1.0
var nom_animation: String = ""

var _loader: SpriterLoader = SpriterLoader.new()
var _donnees: SpriterAnimations = SpriterAnimations.new()
var _customisation_differee_en_cours: bool = false

var _imported_adapter = IMPORTED_ADAPTER_SCRIPT.new()
var _customization = CUSTOMIZATION_SCRIPT.new()

@export var entite_joueur: Node2D
@export var animation_player: AnimationPlayer
@export var sprite_arme: Sprite2D
@export var point_bouche: Marker2D


func _ready() -> void:
	_loader.charger_images(CHEMIN_SCML)
	_donnees.charger(CHEMIN_SCML)
	_customization.initialiser(_donnees, ORDRE_CATEGORIES)

	if not _imported_adapter.initialiser(
			PREFIXE_LIB_ANIM,
			_loader,
			entite_joueur,
			animation_player,
			sprite_arme,
			point_bouche):
		push_error("VisuelPlayer requiert une scène SCML importée valide. Détail: %s" % _imported_adapter.last_error)
		return
	_imported_adapter.animation_terminee.connect(_sur_animation_finie_importee)

	jouer("Idle")


func jouer(nom: String, relancer: bool = false, depart: float = 0.0) -> void:
	vitesse = 2.0 if nom.begins_with("Jump") else 1.0

	var nom_importe: String = _imported_adapter.jouer(nom, relancer, depart, vitesse, nom_animation)
	if not nom_importe.is_empty():
		nom_animation = nom_importe


func _process(_delta: float) -> void:
	if not _customization.cartes_actives().is_empty():
		_programmer_customisation_importee()


func changer_variante(nom: String) -> void:
	var position_actuelle: float = _imported_adapter.position_animation_ms()
	jouer(nom, true, position_actuelle)


func position_bouche(bouche_y: float = 0.3) -> Vector2:
	# Le changement d'arme peut précéder sa customisation différée dans ce tick.
	_appliquer_customisation_importee()
	var position: Vector2 = _imported_adapter.position_bouche(bouche_y)
	return position


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

func miniature_variante(categorie: String, carte: String) -> Texture2D:
	if not SOURCES_MINIATURES.has(categorie):
		push_error("Catégorie inconnue pour la miniature : " + categorie)
		return null

	var source: Vector2i = SOURCES_MINIATURES[categorie]
	var dossier := source.x
	var fichier := source.y

	if not carte.is_empty():
		if not _donnees.cartes.has(carte):
			push_error("Variante inconnue pour la miniature : " + carte)
			return null

		for regle: Dictionary in _donnees.cartes[carte]:
			if int(regle["dossier"]) != source.x:
				continue
			if int(regle["fichier"]) != source.y:
				continue

			dossier = int(regle["cible_dossier"])
			fichier = int(regle["cible_fichier"])
			break

	if dossier < 0 or fichier < 0:
		return null

	var infos_dossier: Dictionary = _loader.dossiers[dossier]
	var info: Dictionary = infos_dossier["fichiers"][fichier]
	var texture := load(String(info["chemin"])) as Texture2D

	if texture == null:
		push_error("Impossible de charger la miniature : " + String(info["chemin"]))
	return texture
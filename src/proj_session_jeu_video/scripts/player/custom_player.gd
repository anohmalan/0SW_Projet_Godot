extends Control

const CATEGORIES := {
	"Head": "Tête",
	"Balaclava": "Cagoule",
	"Mask": "Masque",
	"Googles": "Lunettes",
	"Head Gear": "Casque",
	"Shirt": "Chemise",
	"Jacket": "Veste",
	"Pants": "Pantalon"
}

@onready var _custom_apercu: VisuelPlayer = %VisuelCustom
@onready var _categories: VBoxContainer = %CategoriesCustom
@onready var _titre_categorie: Label = %CategorieActuelleCustom
@onready var _grille: GridContainer = %GrilleCustom
@onready var _statut: Label = %StatutCustom
@onready var _retour: Button = %RetourCustom
@onready var _enregistrer: Button = %EnregistrerCustom

var _selection: Dictionary = {}
var _categorie := "Head"
var _groupe_categories := ButtonGroup.new()

func _ready() -> void:
	_selection = ApparencePlayer.selection.duplicate(true)
	_custom_apercu.appliquer_apparence(_selection)
	_statut.text = ApparencePlayer.erreur_chargement

	for categorie: String in CATEGORIES:
		var bouton := Button.new()
		bouton.text = CATEGORIES[categorie]
		bouton.toggle_mode = true
		bouton.button_group = _groupe_categories
		bouton.button_pressed = categorie == _categorie
		bouton.pressed.connect(_afficher_categorie.bind(categorie))
		_categories.add_child(bouton)

	_afficher_categorie(_categorie)

func _afficher_categorie(categorie: String) -> void:
	_categorie = categorie
	_titre_categorie.text = CATEGORIES[categorie]

	for enfant in _grille.get_children():
		_grille.remove_child(enfant)
		enfant.queue_free()

	var groupe := ButtonGroup.new()
	_ajouter_choix("", "Par défaut", groupe)

	for carte: String in _custom_apercu.variantes(categorie):
		var texte := carte.trim_prefix(categorie + " - ")
		_ajouter_choix(carte, texte, groupe)

func _ajouter_choix(carte: String, texte: String, groupe: ButtonGroup) -> void:
	var bouton := Button.new()
	bouton.text = texte
	bouton.custom_minimum_size = Vector2(150, 70)
	bouton.toggle_mode = true
	bouton.button_group = groupe
	bouton.button_pressed = _selection.get(_categorie, "") == carte
	bouton.pressed.connect(_choisir.bind(_categorie, carte))
	_grille.add_child(bouton)

func _choisir(categorie: String, carte: String) -> void:
	if carte.is_empty():
		_selection.erase(categorie)
	else:
		_selection[categorie] = carte

	_custom_apercu.appliquer_apparence(_selection)
	_statut.text = "Modifications non enregistrées."

func _on_enregistrer_custom_pressed() -> void:
	var erreur := ApparencePlayer.enregistrer(_selection)
	if erreur != OK:
		_statut.text = "Échec de la sauvegarde : " + error_string(erreur)
		return

	_statut.text = "Apparence enregistrée."


func _on_retour_custom_pressed() -> void:
	var erreur := get_tree().change_scene_to_file("res://scenes/menu_principal.tscn")
	if erreur != OK:
		_statut.text = "Impossible de revenir au menu : " + error_string(erreur)
		push_error(_statut.text)

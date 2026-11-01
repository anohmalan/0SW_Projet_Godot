extends Control

const CATEGORIES := {
	"Head": "Tête",
	"Balaclava": "Cagoule",
	"Mask": "Masque",
	"Googles": "Lunettes",
	"Head Gear": "Casque",
	"Shirt": "Chemise",
	"Jacket": "Veste",
	"Pants": "Pantalon",
	"Strap": "Sangle",
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

# func _ajouter_choix(carte: String, texte: String, groupe: ButtonGroup) -> void:
# 	var bouton := Button.new()
# 	bouton.text = texte
# 	bouton.custom_minimum_size = Vector2(150, 70)
# 	bouton.toggle_mode = true
# 	bouton.button_group = groupe
# 	bouton.button_pressed = _selection.get(_categorie, "") == carte
# 	bouton.pressed.connect(_choisir.bind(_categorie, carte))
# 	_grille.add_child(bouton)

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

func _ajouter_choix(carte: String, texte: String, groupe: ButtonGroup) -> void:
	var bouton := Button.new()
	bouton.custom_minimum_size = Vector2(160, 160)
	bouton.toggle_mode = true
	bouton.button_group = groupe
	bouton.button_pressed = _selection.get(_categorie, "") == carte
	bouton.tooltip_text = texte
	bouton.pressed.connect(_choisir.bind(_categorie, carte))

	bouton.add_theme_stylebox_override(
		"normal", _style_carte(Color("#28534D"), Color("#416D65"))
	)
	bouton.add_theme_stylebox_override(
		"hover", _style_carte(Color("#32665C"), Color("#77A89A"))
	)
	bouton.add_theme_stylebox_override(
		"pressed", _style_carte(Color("#32665C"), Color("#B5EC64"))
	)
	bouton.add_theme_stylebox_override(
		"hover_pressed", _style_carte(Color("#397466"), Color("#B5EC64"))
	)

	_grille.add_child(bouton)

	var marge := MarginContainer.new()
	marge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bouton.add_child(marge)
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for cote in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		marge.add_theme_constant_override(cote, 12)

	var colonne := VBoxContainer.new()
	colonne.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marge.add_child(colonne)

	var miniature := TextureRect.new()
	miniature.texture = _custom_apercu.miniature_variante(_categorie, carte)
	miniature.custom_minimum_size = Vector2(0, 100)
	miniature.size_flags_vertical = Control.SIZE_EXPAND_FILL
	miniature.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	miniature.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	miniature.mouse_filter = Control.MOUSE_FILTER_IGNORE
	colonne.add_child(miniature)

	var etiquette := Label.new()
	etiquette.text = texte
	etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiquette.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiquette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	colonne.add_child(etiquette)

func _style_carte(fond: Color, bordure: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fond
	style.border_color = bordure
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	return style

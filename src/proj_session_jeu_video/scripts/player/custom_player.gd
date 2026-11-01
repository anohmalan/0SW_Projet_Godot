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
@onready var _enregistrer_et_quitter: Button = %EnregistrerEtQuitter
@onready var _quitter_sans_sauver: Button = %QuitterSansSauver
@onready var _confirmation_retour: ColorRect = %ConfirmationRetour

var _selection: Dictionary = {}
var _categorie := "Head"
var _groupe_categories := ButtonGroup.new()
var _transfert_confirmation := false
var _focus_avant_confirmation: Control

func _ready() -> void:
	_selection = ApparencePlayer.selection.duplicate(true)
	_custom_apercu.appliquer_apparence(_selection)
	_statut.text = ApparencePlayer.erreur_chargement
	_statut.text = ApparencePlayer.erreur_chargement
	_enregistrer_et_quitter.pressed.connect(_sauvegarder_et_quitter)
	_quitter_sans_sauver.pressed.connect(_retour_menu)

	for categorie: String in CATEGORIES:
		_ajouter_categorie(categorie)

	_afficher_categorie(_categorie, false)

	_styliser_action(_retour, false)
	_styliser_action(_enregistrer, true)
	_styliser_action(_enregistrer_et_quitter, true)
	_styliser_action(_quitter_sans_sauver, false)

	_donner_focus_initial.call_deferred()

	_limiter_focus_dialogue(
		_enregistrer_et_quitter, _quitter_sans_sauver
	)
	_limiter_focus_dialogue(
		_quitter_sans_sauver, _enregistrer_et_quitter
	)

func _input(event: InputEvent) -> void:
	if _transfert_confirmation:
		return

	if _confirmation_retour.visible and event.is_action("retour"):
		get_viewport().set_input_as_handled()
		if event.is_action_pressed("retour") and not event.is_echo():
			_fermer_confirmation()
		return
		
	if event.is_action("confirmer"):
		get_viewport().set_input_as_handled()

		if event.is_echo():
			return

		var validation := InputEventAction.new()
		validation.action = "ui_accept"
		validation.pressed = event.is_action_pressed("confirmer")

		_transfert_confirmation = true
		get_viewport().push_input(validation)
		_transfert_confirmation = false
		return

	if event.is_action("ui_accept"):
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("retour") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_on_retour_custom_pressed()

func _donner_focus_initial() -> void:
	var bouton := _groupe_categories.get_pressed_button()
	if bouton != null:
		bouton.grab_focus()

func _afficher_categorie(categorie: String, transferer_focus: bool = true) -> void:
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

	if transferer_focus:
		_focaliser_choix.call_deferred(groupe)

func _focaliser_choix(groupe: ButtonGroup) -> void:
	var bouton := groupe.get_pressed_button()
	if is_instance_valid(bouton) and bouton.is_inside_tree():
		bouton.grab_focus()

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
	if _confirmation_retour.visible:
		return

	if _selection == ApparencePlayer.selection:
		_retour_menu()
		return

	_focus_avant_confirmation = get_viewport().gui_get_focus_owner()
	_confirmation_retour.show()
	_enregistrer_et_quitter.grab_focus()	

func _ajouter_categorie(categorie: String) -> void:
	var bouton := Button.new()
	bouton.focus_mode = Control.FOCUS_ALL
	bouton.text = CATEGORIES[categorie]
	bouton.custom_minimum_size = Vector2(190, 52)
	bouton.alignment = HORIZONTAL_ALIGNMENT_LEFT
	bouton.icon = _custom_apercu.miniature_variante(categorie, "")
	bouton.expand_icon = true
	bouton.add_theme_constant_override("icon_max_width", 32)
	bouton.add_theme_constant_override("h_separation", 12)
	bouton.add_theme_font_size_override("font_size", 18)

	bouton.toggle_mode = true
	bouton.button_group = _groupe_categories
	bouton.button_pressed = categorie == _categorie
	bouton.pressed.connect(_afficher_categorie.bind(categorie))

	bouton.add_theme_stylebox_override(
		"normal", _style_categorie(Color("#28534D"), Color("#416D65"))
	)
	bouton.add_theme_stylebox_override(
		"hover", _style_categorie(Color("#32665C"), Color("#77A89A"))
	)
	bouton.add_theme_stylebox_override(
		"pressed", _style_categorie(Color("#009D83"), Color("#B5EC64"))
	)
	bouton.add_theme_stylebox_override(
		"hover_pressed", _style_categorie(Color("#00AE91"), Color("#B5EC64"))
	)
	bouton.add_theme_stylebox_override(
		"focus", _style_categorie(Color.TRANSPARENT, Color("#FFFFFF"))
	)

	_categories.add_child(bouton)

func _style_categorie(fond: Color, bordure: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fond
	style.border_color = bordure
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _ajouter_choix(carte: String, texte: String, groupe: ButtonGroup) -> void:
	var bouton := Button.new()
	bouton.focus_mode = Control.FOCUS_ALL
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
	bouton.add_theme_stylebox_override(
		"focus", _style_carte(Color.TRANSPARENT, Color.WHITE)
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

func _styliser_action(bouton: Button, principale: bool) -> void:
	bouton.focus_mode = Control.FOCUS_ALL
	bouton.custom_minimum_size = Vector2(180, 52)
	bouton.add_theme_font_size_override("font_size", 20)
	bouton.add_theme_color_override("font_color", Color("#FFFFFF"))
	bouton.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	bouton.add_theme_color_override("font_pressed_color", Color("#FFFFFF"))

	var fond := Color("#009D83") if principale else Color("#28534D")
	var survol := Color("#00AE91") if principale else Color("#32665C")
	var appui := Color("#007D69") if principale else Color("#1D403B")
	var bordure := Color("#B5EC64") if principale else Color("#77A89A")

	bouton.add_theme_stylebox_override(
		"normal", _style_categorie(fond, bordure)
	)
	bouton.add_theme_stylebox_override(
		"hover", _style_categorie(survol, bordure)
	)
	bouton.add_theme_stylebox_override(
		"pressed", _style_categorie(appui, bordure)
	)
	bouton.add_theme_stylebox_override(
		"focus", _style_categorie(Color.TRANSPARENT, Color.WHITE)
	)

func _sauvegarder_et_quitter() -> void:
	var erreur := ApparencePlayer.enregistrer(_selection)
	if erreur != OK:
		_fermer_confirmation()
		_statut.text = "Échec de la sauvegarde : " + error_string(erreur)
		return

	_retour_menu()

func _retour_menu() -> void:
	var erreur := get_tree().change_scene_to_file(
		"res://scenes/menu_principal.tscn"
	)
	if erreur != OK:
		_fermer_confirmation()
		_statut.text = "Impossible de revenir au menu : " + error_string(erreur)
		push_error(_statut.text)


func _fermer_confirmation() -> void:
	_confirmation_retour.hide()

	if is_instance_valid(_focus_avant_confirmation):
		if _focus_avant_confirmation.is_visible_in_tree():
			_focus_avant_confirmation.grab_focus()
			return

	_retour.grab_focus()


func _limiter_focus_dialogue(bouton: Button, autre: Button) -> void:
	var chemin := bouton.get_path_to(autre)
	bouton.focus_neighbor_top = chemin
	bouton.focus_neighbor_bottom = chemin
	bouton.focus_neighbor_left = chemin
	bouton.focus_neighbor_right = chemin
	bouton.focus_next = chemin
	bouton.focus_previous = chemin

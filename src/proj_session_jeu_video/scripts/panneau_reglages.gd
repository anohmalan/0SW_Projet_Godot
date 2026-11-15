class_name PanneauReglages
extends PanelContainer

## Panneau de réglages réutilisable (menu principal et menu pause) :
## plein écran, volumes, sourdine et configuration des touches.

signal fermer_demande

const COULEUR_TEXTE := Color("#F1F5DF")
const COULEUR_ACCENT := Color("#00D995")
const COULEUR_FOND := Color("#073A35")
const COULEUR_BORDURE := Color("#48A991")

var _plein_ecran: CheckButton
var _sourdine: CheckButton
var _volume_general: HSlider
var _volume_musique: HSlider
var _volume_effets: HSlider
var _boutons_touches := {} # action -> { Peripherique: Button }
var _bouton_retour: Button

## Touche en cours de capture : { action, peripherique, bouton } ou vide.
var _capture := {}


func _ready() -> void:
	add_theme_stylebox_override("panel", _style_panneau())
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 14)
	add_child(colonne)

	colonne.add_child(_titre("RÉGLAGES", 30))
	colonne.add_child(_section_son_affichage())
	colonne.add_child(_titre("TOUCHES", 22))
	colonne.add_child(_section_touches())

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	var reinitialiser := _bouton("Touches par défaut")
	reinitialiser.pressed.connect(Parametres.reinitialiser_touches)
	actions.add_child(reinitialiser)
	_bouton_retour = _bouton("Retour")
	_bouton_retour.pressed.connect(func() -> void: fermer_demande.emit())
	actions.add_child(_bouton_retour)
	colonne.add_child(actions)

	Parametres.touches_changees.connect(_rafraichir_touches)
	rafraichir()


func _exit_tree() -> void:
	if Parametres.touches_changees.is_connected(_rafraichir_touches):
		Parametres.touches_changees.disconnect(_rafraichir_touches)


## Remet les contrôles à jour depuis Parametres et place le focus en haut.
func rafraichir() -> void:
	_annuler_capture()
	_plein_ecran.set_pressed_no_signal(Parametres.plein_ecran)
	_sourdine.set_pressed_no_signal(Parametres.sourdine)
	_volume_general.set_value_no_signal(Parametres.volume_general)
	_volume_musique.set_value_no_signal(Parametres.volume_musique)
	_volume_effets.set_value_no_signal(Parametres.volume_effets)
	_mettre_a_jour_etiquettes()
	_rafraichir_touches()


func donner_focus() -> void:
	_plein_ecran.grab_focus()


func est_en_capture() -> bool:
	return not _capture.is_empty()


# --- Construction ------------------------------------------------------------

func _section_son_affichage() -> Control:
	var grille := GridContainer.new()
	grille.columns = 3
	grille.add_theme_constant_override("h_separation", 18)
	grille.add_theme_constant_override("v_separation", 10)

	_plein_ecran = CheckButton.new()
	Audio.brancher_bouton(_plein_ecran)
	_plein_ecran.toggled.connect(Parametres.definir_plein_ecran)
	_ajouter_ligne(grille, "Plein écran", _plein_ecran, null)

	_volume_general = _curseur()
	var valeur_general := _etiquette("100 %")
	_volume_general.value_changed.connect(func(v: float) -> void:
		Parametres.definir_volume_general(v)
		valeur_general.text = "%d %%" % v)
	_volume_general.set_meta("etiquette", valeur_general)
	_ajouter_ligne(grille, "Volume général", _volume_general, valeur_general)

	_volume_musique = _curseur()
	var valeur_musique := _etiquette("100 %")
	_volume_musique.value_changed.connect(func(v: float) -> void:
		Parametres.definir_volume_musique(v)
		valeur_musique.text = "%d %%" % v)
	_volume_musique.set_meta("etiquette", valeur_musique)
	_ajouter_ligne(grille, "Musique", _volume_musique, valeur_musique)

	_volume_effets = _curseur()
	var valeur_effets := _etiquette("100 %")
	_volume_effets.value_changed.connect(func(v: float) -> void:
		Parametres.definir_volume_effets(v)
		valeur_effets.text = "%d %%" % v)
	_volume_effets.set_meta("etiquette", valeur_effets)
	_ajouter_ligne(grille, "Effets sonores", _volume_effets, valeur_effets)

	_sourdine = CheckButton.new()
	Audio.brancher_bouton(_sourdine)
	_sourdine.toggled.connect(Parametres.definir_sourdine)
	_ajouter_ligne(grille, "Sourdine", _sourdine, null)
	return grille


func _section_touches() -> Control:
	var defilement := ScrollContainer.new()
	defilement.custom_minimum_size = Vector2(0, 230)
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defilement.follow_focus = true

	var grille := GridContainer.new()
	grille.columns = 3
	grille.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grille.add_theme_constant_override("h_separation", 12)
	grille.add_theme_constant_override("v_separation", 8)
	defilement.add_child(grille)

	grille.add_child(_etiquette("Action", COULEUR_ACCENT))
	grille.add_child(_etiquette("Clavier / souris", COULEUR_ACCENT))
	grille.add_child(_etiquette("Manette", COULEUR_ACCENT))

	for action in Parametres.ACTIONS_MODIFIABLES:
		var nom := _etiquette(Parametres.NOMS_ACTIONS.get(action, String(action)))
		nom.custom_minimum_size.x = 160
		grille.add_child(nom)
		_boutons_touches[action] = {}
		for peripherique in [Parametres.Peripherique.CLAVIER, Parametres.Peripherique.MANETTE]:
			var bouton := _bouton("")
			bouton.custom_minimum_size = Vector2(190, 0)
			bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bouton.clip_text = true
			bouton.pressed.connect(_demarrer_capture.bind(action, peripherique, bouton))
			grille.add_child(bouton)
			_boutons_touches[action][peripherique] = bouton
	return defilement


func _ajouter_ligne(grille: GridContainer, texte: String, controle: Control, valeur: Control) -> void:
	var etiquette := _etiquette(texte)
	etiquette.custom_minimum_size.x = 160
	grille.add_child(etiquette)
	controle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controle.focus_mode = Control.FOCUS_ALL
	grille.add_child(controle)
	grille.add_child(valeur if valeur != null else Control.new())


# --- Capture d'une touche ----------------------------------------------------

func _demarrer_capture(action: StringName, peripherique: int, bouton: Button) -> void:
	_annuler_capture()
	bouton.text = "Appuyez…" if peripherique == Parametres.Peripherique.CLAVIER else "Bouton manette…"
	# Différé : l'appui qui a activé le bouton ne doit pas être capturé lui-même.
	set_deferred("_capture", {"action": action, "peripherique": peripherique, "bouton": bouton})


func _annuler_capture() -> void:
	_capture = {}
	_rafraichir_touches()


func _input(event: InputEvent) -> void:
	if _capture.is_empty() or not is_visible_in_tree():
		return
	# Pendant la capture, aucun événement ne doit naviguer dans les menus ni fermer la pause.
	get_viewport().set_input_as_handled()
	if event.is_echo() or not event.is_pressed():
		return
	var touche := event as InputEventKey
	if touche != null and touche.physical_keycode == KEY_ESCAPE:
		_annuler_capture()
		return
	if Parametres.peripherique_de(event) != _capture["peripherique"]:
		return
	var axe := event as InputEventJoypadMotion
	if axe != null and absf(axe.axis_value) < 0.6:
		return
	var action: StringName = _capture["action"]
	var bouton: Button = _capture["bouton"]
	_capture = {}
	Parametres.assigner(action, event)
	bouton.grab_focus()


func _rafraichir_touches() -> void:
	for action in _boutons_touches:
		for peripherique in _boutons_touches[action]:
			var bouton: Button = _boutons_touches[action][peripherique]
			bouton.text = Parametres.description(action, peripherique)
			bouton.tooltip_text = bouton.text


func _mettre_a_jour_etiquettes() -> void:
	for curseur in [_volume_general, _volume_musique, _volume_effets]:
		var etiquette: Label = curseur.get_meta("etiquette")
		etiquette.text = "%d %%" % curseur.value


# --- Style -------------------------------------------------------------------

func _titre(texte: String, taille: int) -> Label:
	var titre := _etiquette(texte, COULEUR_ACCENT)
	titre.add_theme_font_size_override("font_size", taille)
	titre.add_theme_constant_override("outline_size", 4)
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return titre


func _etiquette(texte: String, couleur: Color = COULEUR_TEXTE) -> Label:
	var etiquette := Label.new()
	etiquette.text = texte
	etiquette.add_theme_color_override("font_color", couleur)
	etiquette.add_theme_color_override("font_outline_color", Color("#073A32"))
	etiquette.add_theme_constant_override("outline_size", 2)
	etiquette.add_theme_font_size_override("font_size", 18)
	return etiquette


func _curseur() -> HSlider:
	var curseur := HSlider.new()
	curseur.min_value = 0.0
	curseur.max_value = 100.0
	curseur.step = 5.0
	curseur.custom_minimum_size = Vector2(240, 24)
	curseur.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return curseur


func _bouton(texte: String) -> Button:
	var bouton := Button.new()
	Audio.brancher_bouton(bouton)
	bouton.text = texte
	bouton.focus_mode = Control.FOCUS_ALL
	bouton.add_theme_font_size_override("font_size", 17)
	bouton.add_theme_color_override("font_color", COULEUR_TEXTE)
	bouton.add_theme_color_override("font_hover_color", Color.WHITE)
	bouton.add_theme_color_override("font_focus_color", Color.WHITE)
	bouton.add_theme_stylebox_override("normal", _style_bouton(COULEUR_FOND, COULEUR_BORDURE, false))
	bouton.add_theme_stylebox_override("hover", _style_bouton(Color("#10574B"), COULEUR_BORDURE, false))
	bouton.add_theme_stylebox_override("pressed", _style_bouton(Color("#0B4037"), COULEUR_BORDURE, false))
	bouton.add_theme_stylebox_override("focus", _style_bouton(Color("#0E6B57"), Color.WHITE, true))
	return bouton


func _style_bouton(fond: Color, bordure: Color, illumine: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fond
	style.border_color = bordure
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	if illumine:
		style.shadow_color = Color(0.0, 1.0, 0.62, 0.6)
		style.shadow_size = 10
	return style


func _style_panneau() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.027, 0.227, 0.208, 0.95)
	style.border_color = COULEUR_BORDURE
	style.set_border_width_all(2)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 24
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style

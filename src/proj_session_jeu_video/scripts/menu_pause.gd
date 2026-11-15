class_name MenuPause
extends CanvasLayer

## Menu pause du niveau. Tourne pendant la pause (process_mode = Always) ; le reste du jeu est figé.

const SCENE_MENU_PRINCIPAL := "res://scenes/menu_principal.tscn"

@onready var _panneau_pause: Control = $Centre/Panneau
@onready var _reprendre: Button = %Reprendre
@onready var _recommencer: Button = %Recommencer
@onready var _reglages: Button = %Reglages
@onready var _menu_principal: Button = %MenuPrincipal
@onready var _panneau_reglages: PanneauReglages = %PanneauReglages


func _ready() -> void:
	visible = false
	_reprendre.pressed.connect(fermer)
	_recommencer.pressed.connect(_recommencer_niveau)
	_reglages.pressed.connect(_ouvrir_reglages)
	_menu_principal.pressed.connect(_retour_menu_principal)
	_panneau_reglages.fermer_demande.connect(_fermer_reglages)

	var boutons: Array[Button] = [_reprendre, _recommencer, _reglages, _menu_principal]
	for i in boutons.size():
		var bouton := boutons[i]
		_styliser_bouton(bouton)
		# Navigation en boucle, de haut en bas, au clavier comme à la manette.
		var precedent := boutons[posmod(i - 1, boutons.size())]
		var suivant := boutons[(i + 1) % boutons.size()]
		bouton.focus_neighbor_top = bouton.get_path_to(precedent)
		bouton.focus_neighbor_bottom = bouton.get_path_to(suivant)
		bouton.focus_previous = bouton.get_path_to(precedent)
		bouton.focus_next = bouton.get_path_to(suivant)
		bouton.focus_neighbor_left = bouton.get_path()
		bouton.focus_neighbor_right = bouton.get_path()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	var touche := event as InputEventKey
	var echap: bool = touche != null and touche.pressed and touche.physical_keycode == KEY_ESCAPE
	var basculer := event.is_action_pressed("pause") or echap
	var retour := visible and event.is_action_pressed("retour")
	if not (basculer or retour):
		return
	get_viewport().set_input_as_handled()
	if _panneau_reglages.visible:
		# Depuis les réglages, Pause/Échap/Retour ramènent d'abord au menu pause.
		_fermer_reglages()
	elif visible:
		fermer()
	elif basculer:
		ouvrir()


func ouvrir() -> void:
	visible = true
	_panneau_reglages.visible = false
	_panneau_pause.visible = true
	get_tree().paused = true
	_reprendre.grab_focus()


func fermer() -> void:
	visible = false
	get_tree().paused = false


func _ouvrir_reglages() -> void:
	_panneau_pause.visible = false
	_panneau_reglages.visible = true
	_panneau_reglages.rafraichir()
	_panneau_reglages.donner_focus()


func _fermer_reglages() -> void:
	_panneau_reglages.visible = false
	_panneau_pause.visible = true
	_reglages.grab_focus()


func _recommencer_niveau() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _retour_menu_principal() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(SCENE_MENU_PRINCIPAL)


# Même style que les boutons du menu principal.
func _styliser_bouton(bouton: Button) -> void:
	bouton.focus_mode = Control.FOCUS_ALL
	bouton.custom_minimum_size = Vector2(260, 0)
	bouton.add_theme_font_size_override("font_size", 22)
	bouton.add_theme_color_override("font_color", Color("#F1F5DF"))
	bouton.add_theme_color_override("font_hover_color", Color.WHITE)
	bouton.add_theme_color_override("font_focus_color", Color.WHITE)
	bouton.add_theme_color_override("font_pressed_color", Color.WHITE)
	bouton.add_theme_color_override("font_outline_color", Color("#073A32"))
	bouton.add_theme_constant_override("outline_size", 2)
	var bordure := Color("#48A991")
	bouton.add_theme_stylebox_override("normal", _style(Color("#073A35"), bordure, false))
	bouton.add_theme_stylebox_override("hover", _style(Color("#10574B"), bordure, true))
	bouton.add_theme_stylebox_override("pressed", _style(Color("#0B4037"), bordure, false))
	bouton.add_theme_stylebox_override("focus", _style(Color("#00D995"), Color.WHITE, true))


func _style(fond: Color, bordure: Color, illumine: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fond
	style.border_color = bordure
	style.set_border_width_all(2)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	if illumine:
		style.shadow_color = Color(0.0, 1.0, 0.62, 0.72)
		style.shadow_size = 20
	return style

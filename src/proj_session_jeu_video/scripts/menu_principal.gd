extends Control

@onready var _visuel: VisuelPlayer = %VisuelMenu
@onready var _vue: SubViewport = $Marge/Colonne/Apercu/Vue
@onready var _fond: Node2D = $arriere_plan_menu
@onready var _titre: Control = $Marge/Colonne/BandeauTitre/Titre
@onready var _jouer: Button = %Jouer
@onready var _customisation: Button = %Customisation
@onready var _reglages: Button = %Reglages
@onready var _quitter: Button = %Quitter
@onready var _statut: Label = %StatutMenu

var _transfert_confirmation := false
var _position_fond_initiale := Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_position_fond_initiale = _fond.position
	_visuel.appliquer_apparence(ApparencePlayer.selection)
	_statut.text = ApparencePlayer.erreur_chargement

	_jouer.pressed.connect(
		_ouvrir_scene.bind("res://scenes/choisir_niveau.tscn")
	)
	_customisation.pressed.connect(
		_ouvrir_scene.bind("res://scenes/custom_player.tscn")
	)
	_reglages.pressed.connect(
		_ouvrir_scene.bind("res://scenes/reglages.tscn")
	)
	_quitter.pressed.connect(_quitter_jeu)

	var boutons: Array[Button] = [
		_jouer, _customisation, _reglages, _quitter
	]

	for index in range(boutons.size()):
		var bouton := boutons[index]
		_styliser_bouton(bouton, false)

		var precedent := boutons[posmod(index - 1, boutons.size())]
		var suivant := boutons[(index + 1) % boutons.size()]

		bouton.focus_neighbor_left = bouton.get_path_to(precedent)
		bouton.focus_neighbor_right = bouton.get_path_to(suivant)
		bouton.focus_previous = bouton.get_path_to(precedent)
		bouton.focus_next = bouton.get_path_to(suivant)
		bouton.focus_neighbor_top = bouton.get_path()
		bouton.focus_neighbor_bottom = bouton.get_path()

	_vue.size_changed.connect(_centrer_soldat)
	_centrer_soldat.call_deferred()
	_titre.modulate.a = 0.0
	create_tween().tween_property(
		_titre, "modulate:a", 1.0, 0.7
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_jouer.grab_focus.call_deferred()

func _centrer_soldat() -> void:
	var taille := Vector2(_vue.size)
	_visuel.position = Vector2(taille.x * 0.5, taille.y * 0.72)


func _process(delta: float) -> void:
	var taille := get_viewport_rect().size
	if taille.x > 0.0 and taille.y > 0.0:
		var pointeur := get_viewport().get_mouse_position() / taille
		var decalage := Vector2(
			(0.5 - pointeur.x) * 7.0,
			(0.5 - pointeur.y) * 4.0
		)
		_fond.position = _fond.position.lerp(
			_position_fond_initiale + decalage, minf(delta * 2.0, 1.0)
		)


func _ouvrir_scene(chemin: String) -> void:
	var erreur := get_tree().change_scene_to_file(chemin)
	if erreur != OK:
		_statut.text = "Impossible d'ouvrir la scène : " + error_string(erreur)
		push_error("%s — %s" % [_statut.text, chemin])


func _quitter_jeu() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if _transfert_confirmation:
		return

	if event.is_action("confirmer"):
		get_viewport().set_input_as_handled()

		if event.is_echo():
			return

		var validation := InputEventAction.new()
		validation.action = &"ui_accept"
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
		_jouer.grab_focus()

func _styliser_bouton(bouton: Button, principal: bool) -> void:
	bouton.focus_mode = Control.FOCUS_ALL
	bouton.add_theme_font_size_override("font_size", 22)
	bouton.add_theme_color_override("font_color", Color("#F1F5DF"))
	bouton.add_theme_color_override("font_hover_color", Color.WHITE)
	bouton.add_theme_color_override("font_pressed_color", Color.WHITE)
	bouton.add_theme_color_override("font_outline_color", Color("#073A32"))
	bouton.add_theme_constant_override("outline_size", 2)

	var fond := Color("#00D995") if principal else Color("#073A35")
	var survol := Color("#38FFC0") if principal else Color("#10574B")
	var bordure := Color("#71FFC0") if principal else Color("#48A991")

	bouton.add_theme_stylebox_override(
		"normal", _style_bouton(fond, bordure, false)
	)
	bouton.add_theme_stylebox_override(
		"hover", _style_bouton(survol, bordure, true)
	)
	bouton.add_theme_stylebox_override(
		"pressed", _style_bouton(Color("#0B4037"), bordure, false)
	)
	bouton.add_theme_stylebox_override(
		"focus",
		_style_bouton(
			Color("#00D995"),
			Color.WHITE,
			true
		)
	)

func _style_bouton(
	fond: Color, bordure: Color, illumine: bool
) -> StyleBoxFlat:
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

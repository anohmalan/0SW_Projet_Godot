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
	for bouton in boutons:
		StyleMenu.styliser_bouton(bouton)
	StyleMenu.chainer_focus_vertical(boutons)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	# Jeu déjà mis en pause par un autre écran (ex. victoire) : la pause ne s'en mêle pas.
	if get_tree().paused and not visible:
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


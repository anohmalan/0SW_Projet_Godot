extends Control

## Écran Réglages ouvert depuis le menu principal.

const SCENE_MENU_PRINCIPAL := "res://scenes/menu_principal.tscn"

@onready var _panneau: PanneauReglages = %PanneauReglages


func _ready() -> void:
	_panneau.fermer_demande.connect(_retour_menu)
	_panneau.donner_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("retour") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_retour_menu()


func _retour_menu() -> void:
	get_tree().change_scene_to_file(SCENE_MENU_PRINCIPAL)

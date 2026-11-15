extends Node

## Réglages du joueur (son, affichage, touches) : appliqués au démarrage et sauvegardés
## dans user://parametres.cfg. Autoload « Parametres ».

signal touches_changees

const CHEMIN := "user://parametres.cfg"

enum Peripherique { CLAVIER, MANETTE }

## Actions de jeu que le joueur peut réassigner, dans l'ordre d'affichage.
const ACTIONS_MODIFIABLES: Array[StringName] = [
	&"gauche", &"droite", &"bas", &"saut", &"tir", &"melee",
	&"arme_suivante", &"arme_précédente", &"pause",
]
const NOMS_ACTIONS := {
	&"gauche": "Gauche",
	&"droite": "Droite",
	&"bas": "S'accroupir",
	&"saut": "Sauter",
	&"tir": "Tirer",
	&"melee": "Couteau",
	&"arme_suivante": "Arme suivante",
	&"arme_précédente": "Arme précédente",
	&"pause": "Pause",
}
## Noms des boutons de manette PlayStation (indices SDL de Godot).
const NOMS_BOUTONS_MANETTE := {
	0: "Croix", 1: "Rond", 2: "Carré", 3: "Triangle", 4: "Créer", 5: "PS",
	6: "Options", 7: "L3", 8: "R3", 9: "L1", 10: "R1",
	11: "Croix dir. ↑", 12: "Croix dir. ↓", 13: "Croix dir. ←", 14: "Croix dir. →",
}
const NOMS_AXES_MANETTE := {
	0: ["Stick G ←", "Stick G →"], 1: ["Stick G ↑", "Stick G ↓"],
	2: ["Stick D ←", "Stick D →"], 3: ["Stick D ↑", "Stick D ↓"],
	4: ["L2", "L2"], 5: ["R2", "R2"],
}

var volume_general := 100.0
var volume_musique := 100.0
var sourdine := false
var plein_ecran := false

var _touches_defaut := {}


func _ready() -> void:
	# Les touches du projet servent de valeurs par défaut pour « Réinitialiser ».
	for action in ACTIONS_MODIFIABLES:
		_touches_defaut[action] = _copier(InputMap.action_get_events(action))
	_charger()
	appliquer_audio()
	appliquer_affichage()


# --- Son et affichage --------------------------------------------------------

func definir_volume_general(valeur: float) -> void:
	volume_general = clampf(valeur, 0.0, 100.0)
	appliquer_audio()
	enregistrer()


func definir_volume_musique(valeur: float) -> void:
	volume_musique = clampf(valeur, 0.0, 100.0)
	appliquer_audio()
	enregistrer()


func definir_sourdine(actif: bool) -> void:
	sourdine = actif
	appliquer_audio()
	enregistrer()


func definir_plein_ecran(actif: bool) -> void:
	plein_ecran = actif
	appliquer_affichage()
	enregistrer()


func appliquer_audio() -> void:
	_regler_bus(&"Master", volume_general)
	_regler_bus(&"Musique", volume_musique)
	var master := AudioServer.get_bus_index(&"Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, sourdine)


func appliquer_affichage() -> void:
	var mode := DisplayServer.window_get_mode()
	var est_plein_ecran := mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if plein_ecran and not est_plein_ecran:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not plein_ecran and est_plein_ecran:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _regler_bus(nom: StringName, valeur: float) -> void:
	var index := AudioServer.get_bus_index(nom)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(valeur / 100.0))


# --- Touches -----------------------------------------------------------------

static func peripherique_de(evenement: InputEvent) -> int:
	if evenement is InputEventKey or evenement is InputEventMouseButton:
		return Peripherique.CLAVIER
	if evenement is InputEventJoypadButton or evenement is InputEventJoypadMotion:
		return Peripherique.MANETTE
	return -1


func evenements(action: StringName, peripherique: int) -> Array[InputEvent]:
	var resultat: Array[InputEvent] = []
	for evenement in InputMap.action_get_events(action):
		if peripherique_de(evenement) == peripherique:
			resultat.append(evenement)
	return resultat


## Texte affiché pour les touches d'une action sur un périphérique (ex. « D / Croix dir. → »).
func description(action: StringName, peripherique: int) -> String:
	var noms: PackedStringArray = []
	for evenement in evenements(action, peripherique):
		noms.append(nom_evenement(evenement))
	return " / ".join(noms) if not noms.is_empty() else "—"


## Remplace, dans l'action, les événements du même type que le nouveau (touche ou souris,
## bouton de manette, axe de manette), et retire ce même événement des autres actions.
func assigner(action: StringName, evenement: InputEvent) -> void:
	var nouvel := normaliser(evenement)
	if nouvel == null:
		return
	for autre in ACTIONS_MODIFIABLES:
		for existant in InputMap.action_get_events(autre):
			if _identiques(existant, nouvel) or (autre == action and _meme_type(existant, nouvel)):
				InputMap.action_erase_event(autre, existant)
	InputMap.action_add_event(action, nouvel)
	enregistrer()
	touches_changees.emit()


func reinitialiser_touches() -> void:
	for action in ACTIONS_MODIFIABLES:
		InputMap.action_erase_events(action)
		for evenement in _copier(_touches_defaut[action]):
			InputMap.action_add_event(action, evenement)
	enregistrer()
	touches_changees.emit()


## Copie épurée d'un événement capturé : seule l'identité de la touche est gardée.
static func normaliser(evenement: InputEvent) -> InputEvent:
	if evenement is InputEventKey:
		var touche := InputEventKey.new()
		touche.physical_keycode = evenement.physical_keycode if evenement.physical_keycode != 0 \
			else evenement.keycode
		return touche
	if evenement is InputEventMouseButton:
		var souris := InputEventMouseButton.new()
		souris.button_index = evenement.button_index
		return souris
	if evenement is InputEventJoypadButton:
		var bouton := InputEventJoypadButton.new()
		bouton.device = -1
		bouton.button_index = evenement.button_index
		return bouton
	if evenement is InputEventJoypadMotion:
		var axe := InputEventJoypadMotion.new()
		axe.device = -1
		axe.axis = evenement.axis
		axe.axis_value = signf(evenement.axis_value)
		return axe
	return null


static func nom_evenement(evenement: InputEvent) -> String:
	if evenement is InputEventKey:
		var code: Key = evenement.physical_keycode
		if code != KEY_NONE:
			code = DisplayServer.keyboard_get_keycode_from_physical(code)
		else:
			code = evenement.keycode
		return OS.get_keycode_string(code)
	if evenement is InputEventMouseButton:
		match evenement.button_index:
			MOUSE_BUTTON_LEFT: return "Clic gauche"
			MOUSE_BUTTON_RIGHT: return "Clic droit"
			MOUSE_BUTTON_MIDDLE: return "Clic molette"
		return "Souris %d" % evenement.button_index
	if evenement is InputEventJoypadButton:
		return NOMS_BOUTONS_MANETTE.get(evenement.button_index, "Bouton %d" % evenement.button_index)
	if evenement is InputEventJoypadMotion:
		var noms: Array = NOMS_AXES_MANETTE.get(evenement.axis, ["Axe %d -" % evenement.axis, "Axe %d +" % evenement.axis])
		return noms[1] if evenement.axis_value > 0.0 else noms[0]
	return "?"


static func _identiques(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var code_a: int = a.physical_keycode if a.physical_keycode != 0 else a.keycode
		var code_b: int = b.physical_keycode if b.physical_keycode != 0 else b.keycode
		return code_a == code_b
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and signf(a.axis_value) == signf(b.axis_value)
	return false


static func _meme_type(a: InputEvent, b: InputEvent) -> bool:
	if peripherique_de(a) == Peripherique.CLAVIER and peripherique_de(b) == Peripherique.CLAVIER:
		return true
	return a.get_class() == b.get_class()


static func _copier(liste: Array) -> Array[InputEvent]:
	var copie: Array[InputEvent] = []
	for evenement in liste:
		copie.append(evenement.duplicate())
	return copie


# --- Sauvegarde --------------------------------------------------------------

func enregistrer() -> void:
	var fichier := ConfigFile.new()
	fichier.set_value("son", "volume_general", volume_general)
	fichier.set_value("son", "volume_musique", volume_musique)
	fichier.set_value("son", "sourdine", sourdine)
	fichier.set_value("affichage", "plein_ecran", plein_ecran)
	for action in ACTIONS_MODIFIABLES:
		var liste: Array = []
		for evenement in InputMap.action_get_events(action):
			var donnees := _serialiser(evenement)
			if not donnees.is_empty():
				liste.append(donnees)
		fichier.set_value("touches", String(action), liste)
	var erreur := fichier.save(CHEMIN)
	if erreur != OK:
		push_error("Sauvegarde des réglages impossible : " + error_string(erreur))


func _charger() -> void:
	if not FileAccess.file_exists(CHEMIN):
		return
	var fichier := ConfigFile.new()
	var erreur := fichier.load(CHEMIN)
	if erreur != OK:
		push_error("Lecture des réglages impossible : " + error_string(erreur))
		return
	volume_general = float(fichier.get_value("son", "volume_general", volume_general))
	volume_musique = float(fichier.get_value("son", "volume_musique", volume_musique))
	sourdine = bool(fichier.get_value("son", "sourdine", sourdine))
	plein_ecran = bool(fichier.get_value("affichage", "plein_ecran", plein_ecran))
	for action in ACTIONS_MODIFIABLES:
		var liste: Variant = fichier.get_value("touches", String(action), null)
		if not liste is Array:
			continue
		InputMap.action_erase_events(action)
		for donnees in liste:
			var evenement := _deserialiser(donnees)
			if evenement != null:
				InputMap.action_add_event(action, evenement)


static func _serialiser(evenement: InputEvent) -> Dictionary:
	var e := normaliser(evenement)
	if e is InputEventKey:
		return {"type": "touche", "code": e.physical_keycode}
	if e is InputEventMouseButton:
		return {"type": "souris", "bouton": e.button_index}
	if e is InputEventJoypadButton:
		return {"type": "manette_bouton", "bouton": e.button_index}
	if e is InputEventJoypadMotion:
		return {"type": "manette_axe", "axe": e.axis, "sens": e.axis_value}
	return {}


static func _deserialiser(donnees: Variant) -> InputEvent:
	if not donnees is Dictionary:
		return null
	match donnees.get("type", ""):
		"touche":
			var touche := InputEventKey.new()
			touche.physical_keycode = int(donnees.get("code", 0))
			return touche
		"souris":
			var souris := InputEventMouseButton.new()
			souris.button_index = int(donnees.get("bouton", 1))
			return souris
		"manette_bouton":
			var bouton := InputEventJoypadButton.new()
			bouton.device = -1
			bouton.button_index = int(donnees.get("bouton", 0))
			return bouton
		"manette_axe":
			var axe := InputEventJoypadMotion.new()
			axe.device = -1
			axe.axis = int(donnees.get("axe", 0))
			axe.axis_value = float(donnees.get("sens", 1.0))
			return axe
	return null

extends Node

## Progression du joueur, sauvegardée dans user://progression.cfg. Autoload « Progression ».
## Pour chaque niveau (identifiant libre, ex. "niveau_1") : terminé ou non, et ses records
## (meilleur temps, moins de morts, plus d'ennemis vaincus).

const CHEMIN := "user://progression.cfg"
const SECTION_NIVEAUX := "niveaux"

var _niveaux := {} # identifiant -> { termine, meilleur_temps, moins_de_morts, plus_d_ennemis }


func _ready() -> void:
	_charger()


func est_termine(identifiant: String) -> bool:
	return bool(_niveaux.get(identifiant, {}).get("termine", false))


## Records d'un niveau ; vide s'il n'a jamais été terminé.
func records(identifiant: String) -> Dictionary:
	return (_niveaux.get(identifiant, {}) as Dictionary).duplicate()


## Le premier niveau est toujours ouvert ; les suivants s'ouvrent quand le précédent est terminé.
func est_debloque(index: int, identifiants: Array) -> bool:
	if index <= 0:
		return true
	return est_termine(String(identifiants[index - 1]))


## Enregistre une victoire et renvoie, pour l'écran de fin, les anciens records et ceux battus :
## { ancien_temps, nouveau_temps (bool), nouveau_morts (bool), nouveau_ennemis (bool), premiere_fois (bool) }
func enregistrer_victoire(identifiant: String, temps: float, morts: int, ennemis: int) -> Dictionary:
	var ancien: Dictionary = _niveaux.get(identifiant, {})
	var premiere_fois := not bool(ancien.get("termine", false))
	var resultat := {
		"premiere_fois": premiere_fois,
		"ancien_temps": ancien.get("meilleur_temps", -1.0),
		"nouveau_temps": premiere_fois or temps < float(ancien.get("meilleur_temps", INF)),
		"nouveau_morts": premiere_fois or morts < int(ancien.get("moins_de_morts", 1 << 30)),
		"nouveau_ennemis": premiere_fois or ennemis > int(ancien.get("plus_d_ennemis", -1)),
	}
	_niveaux[identifiant] = {
		"termine": true,
		"meilleur_temps": temps if resultat["nouveau_temps"] else float(ancien["meilleur_temps"]),
		"moins_de_morts": morts if resultat["nouveau_morts"] else int(ancien["moins_de_morts"]),
		"plus_d_ennemis": ennemis if resultat["nouveau_ennemis"] else int(ancien["plus_d_ennemis"]),
	}
	_enregistrer()
	return resultat


func formater_temps(secondes: float) -> String:
	var total := int(secondes)
	return "%d:%02d" % [total / 60, total % 60]


func _enregistrer() -> void:
	var fichier := ConfigFile.new()
	for identifiant in _niveaux:
		fichier.set_value(SECTION_NIVEAUX, identifiant, _niveaux[identifiant])
	var erreur := fichier.save(CHEMIN)
	if erreur != OK:
		push_error("Sauvegarde de la progression impossible : " + error_string(erreur))


func _charger() -> void:
	if not FileAccess.file_exists(CHEMIN):
		return
	var fichier := ConfigFile.new()
	var erreur := fichier.load(CHEMIN)
	if erreur != OK:
		push_error("Lecture de la progression impossible : " + error_string(erreur))
		return
	if not fichier.has_section(SECTION_NIVEAUX):
		return
	for identifiant in fichier.get_section_keys(SECTION_NIVEAUX):
		var donnees: Variant = fichier.get_value(SECTION_NIVEAUX, identifiant)
		if donnees is Dictionary:
			_niveaux[identifiant] = donnees

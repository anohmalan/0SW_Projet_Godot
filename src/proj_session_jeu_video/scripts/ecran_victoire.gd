class_name EcranVictoire
extends CanvasLayer

## Écran de fin de niveau : « Niveau terminé » (victoire) ou « Game Over » (plus de cœurs),
## avec les statistiques de la partie et la suite (rejouer, niveaux, menu).

const SCENE_MENU_PRINCIPAL := "res://scenes/menu_principal.tscn"
const SCENE_CHOIX_NIVEAU := "res://scenes/choisir_niveau.tscn"
const COULEUR_VICTOIRE := Color(0.247, 0.878, 1.0)
const COULEUR_DEFAITE := Color("#FF3355")

@onready var _contenu: Control = $Centre
@onready var _titre: Label = $Centre/Panneau/Colonne/Titre
@onready var _statistiques: Label = %Statistiques
@onready var _rejouer: Button = %Rejouer
@onready var _niveaux: Button = %Niveaux
@onready var _menu_principal: Button = %MenuPrincipal


func _ready() -> void:
	visible = false
	var boutons: Array[Button] = [_rejouer, _niveaux, _menu_principal]
	for bouton in boutons:
		StyleMenu.styliser_bouton(bouton)
	StyleMenu.chainer_focus_vertical(boutons)
	_rejouer.pressed.connect(_changer_scene.bind(""))
	_niveaux.pressed.connect(_changer_scene.bind(SCENE_CHOIX_NIVEAU))
	_menu_principal.pressed.connect(_changer_scene.bind(SCENE_MENU_PRINCIPAL))


## records : résultat de Progression.enregistrer_victoire() (vide pour un Game Over).
func afficher(temps: float, ennemis_vaincus: int, morts: int, victoire: bool = true,
		records: Dictionary = {}) -> void:
	_titre.text = "NIVEAU TERMINÉ" if victoire else "GAME OVER"
	_titre.add_theme_color_override("font_color", COULEUR_VICTOIRE if victoire else COULEUR_DEFAITE)
	_rejouer.text = "Rejouer" if victoire else "Réessayer"
	_statistiques.text = _texte_statistiques(temps, ennemis_vaincus, morts, records)
	visible = true
	get_tree().paused = true
	_contenu.modulate.a = 0.0
	create_tween().tween_property(_contenu, "modulate:a", 1.0, 0.4)
	_rejouer.grab_focus()


## Chemin vide : recharge le niveau en cours.
func _changer_scene(chemin: String) -> void:
	get_tree().paused = false
	if chemin.is_empty():
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(chemin)


## Statistiques de la partie ; en cas de victoire, les records battus sont signalés.
func _texte_statistiques(temps: float, ennemis: int, morts: int, records: Dictionary) -> String:
	var record := func(cle: String) -> String:
		return "   — nouveau record !" if records.get(cle, false) and not records.get("premiere_fois", false) else ""
	var lignes: PackedStringArray = []
	if records.get("premiere_fois", false):
		lignes.append("Premier passage réussi !")
	lignes.append("Temps : %s%s" % [Progression.formater_temps(temps), record.call("nouveau_temps")])
	if records.get("nouveau_temps", false) and float(records.get("ancien_temps", -1.0)) >= 0.0:
		lignes.append("(ancien record : %s)" % Progression.formater_temps(records["ancien_temps"]))
	lignes.append("Ennemis vaincus : %d%s" % [ennemis, record.call("nouveau_ennemis")])
	lignes.append("Morts : %d%s" % [morts, record.call("nouveau_morts")])
	return "\n".join(lignes)

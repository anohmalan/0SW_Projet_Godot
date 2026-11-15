class_name HUD
extends CanvasLayer

## Affiche la vie, l'arme et les munitions du joueur à partir de ses signaux.

const COULEUR_PLEINE := Color("#00D995")
const COULEUR_CRITIQUE := Color("#FF3355")
const SEUIL_CRITIQUE := 0.3
const COULEUR_TEXTE := Color("#F1F5DF")

@onready var _panneau: Control = %Panneau
@onready var _barre_vie: ProgressBar = %BarreVie
@onready var _texte_vie: Label = %TexteVie
@onready var _nom_arme: Label = %NomArme
@onready var _munitions: Label = %Munitions
@onready var minimap: Minimap = %Minimap

var _style_vie: StyleBoxFlat
var _vie_precedente := -1
var _tween_vie: Tween
var _tween_flash: Tween


func _ready() -> void:
	# Copie propre à cette instance : sa couleur change avec la vie.
	_style_vie = _barre_vie.get_theme_stylebox("fill").duplicate()
	_barre_vie.add_theme_stylebox_override("fill", _style_vie)


func brancher(player: Player) -> void:
	player.vie_changee.connect(_sur_vie_changee)
	player.arme_changee.connect(_sur_arme_changee)
	player.munitions_changees.connect(_sur_munitions_changees)
	# Le joueur a déjà émis ses valeurs de départ : on les redemande.
	player.rafraichir()


func _sur_vie_changee(vie: int, vie_max: int) -> void:
	_barre_vie.max_value = vie_max
	if _tween_vie:
		_tween_vie.kill()
	_tween_vie = create_tween()
	_tween_vie.tween_property(_barre_vie, "value", float(vie), 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_texte_vie.text = "%d / %d" % [vie, vie_max]

	var critique := float(vie) / float(vie_max) <= SEUIL_CRITIQUE
	_style_vie.bg_color = COULEUR_CRITIQUE if critique else COULEUR_PLEINE
	_texte_vie.modulate = COULEUR_CRITIQUE if critique else Color.WHITE

	if _vie_precedente >= 0 and vie < _vie_precedente:
		_flasher_panneau()
	_vie_precedente = vie


func _sur_arme_changee(arme: Arme, munitions: int) -> void:
	_nom_arme.text = arme.nom
	_sur_munitions_changees(munitions)


func _sur_munitions_changees(munitions: int) -> void:
	_munitions.text = "∞" if munitions < 0 else str(munitions)
	_munitions.modulate = COULEUR_CRITIQUE if munitions == 0 else Color.WHITE


func _flasher_panneau() -> void:
	if _tween_flash:
		_tween_flash.kill()
	_panneau.modulate = Color(1.0, 0.45, 0.45)
	_tween_flash = create_tween()
	_tween_flash.tween_property(_panneau, "modulate", Color.WHITE, 0.3)

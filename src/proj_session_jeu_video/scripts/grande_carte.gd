class_name GrandeCarte
extends CanvasLayer

## Carte du niveau en plein écran (action « carte ») : le jeu est en pause pendant
## qu'elle est ouverte. Montre tout le niveau avec le joueur, le drapeau, les ennemis,
## les butins et la zone visible à l'écran.

const COULEUR_CADRE := Color(0.282, 0.663, 0.569, 1)
const COULEUR_FOND_CARTE := Color(0.02, 0.12, 0.11, 0.92)

@onready var _zone: Control = %Zone
@onready var _legende: RichTextLabel = %Legende
@onready var _aide: Label = %Aide

var _carte: CarteNiveau
var _player: Player
var _temps := 0.0


func _ready() -> void:
	visible = false
	set_process(false)
	_zone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_zone.draw.connect(_dessiner)
	_legende.text = _texte_legende()


func configurer(carte: CarteNiveau, player: Player) -> void:
	_carte = carte
	_player = player


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if not visible:
		# Ne s'ouvre pas par-dessus un autre écran qui a déjà mis le jeu en pause.
		if event.is_action_pressed("carte") and not get_tree().paused and _carte != null:
			get_viewport().set_input_as_handled()
			ouvrir()
		return
	var touche := event as InputEventKey
	var echap: bool = touche != null and touche.pressed and touche.physical_keycode == KEY_ESCAPE
	if echap or event.is_action_pressed("carte") or event.is_action_pressed("retour") \
			or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		fermer()


func ouvrir() -> void:
	visible = true
	get_tree().paused = true
	_aide.text = "%s / Échap : fermer" % Parametres.description(&"carte", Parametres.Peripherique.CLAVIER)
	_temps = 0.0
	set_process(true)
	_zone.queue_redraw()


func fermer() -> void:
	visible = false
	get_tree().paused = false
	set_process(false)


func _process(delta: float) -> void:
	_temps += delta
	_zone.queue_redraw()


# --- Dessin ------------------------------------------------------------------

## Rectangle où l'image du niveau est dessinée : centré, proportions conservées.
func _rect_carte() -> Rect2:
	var disponible := _zone.size
	var echelle := minf(disponible.x / _carte.cases.size.x, disponible.y / _carte.cases.size.y)
	var taille := Vector2(_carte.cases.size) * echelle
	return Rect2((disponible - taille) * 0.5, taille)


func _vers_carte(position_monde: Vector2, rect: Rect2) -> Vector2:
	return rect.position + _carte.en_cases(position_monde) * (rect.size / Vector2(_carte.cases.size))


func _dessiner() -> void:
	if _carte == null or not _carte.est_valide():
		return
	var rect := _rect_carte()
	_zone.draw_rect(rect.grow(8.0), COULEUR_FOND_CARTE)
	_zone.draw_rect(rect.grow(8.0), COULEUR_CADRE, false, 2.0)
	_zone.draw_texture_rect(_carte.texture, rect, false)
	var pulsation := 0.5 + 0.5 * sin(_temps * 5.0)

	# Zone visible à l'écran.
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		var demi := get_viewport().get_visible_rect().size / camera.zoom * 0.5
		var centre := camera.get_screen_center_position()
		var a := _vers_carte(centre - demi, rect)
		var b := _vers_carte(centre + demi, rect)
		_zone.draw_rect(Rect2(a, b - a).abs(), CarteNiveau.COULEUR_VUE, false, 1.5)

	for butin in get_tree().get_nodes_in_group(&"butins"):
		_zone.draw_circle(_vers_carte(butin.global_position, rect), 3.0, CarteNiveau.COULEUR_BUTIN)
	for noeud in get_tree().get_nodes_in_group(&"ennemis"):
		var ennemi := noeud as Enemy
		if ennemi != null and ennemi.vie > 0:
			_zone.draw_circle(_vers_carte(ennemi.global_position, rect), 4.5, CarteNiveau.couleur_ennemi(ennemi))

	# Drapeau : l'objectif, avec un halo pulsant pour qu'il saute aux yeux.
	var drapeau := get_tree().get_first_node_in_group(&"drapeau") as Node2D
	if drapeau != null:
		var pied := _vers_carte(drapeau.global_position, rect)
		var halo: Color = CarteNiveau.COULEUR_DRAPEAU
		halo.a = 0.15 + 0.2 * pulsation
		_zone.draw_circle(pied + Vector2(0, -10), 16.0 + 4.0 * pulsation, halo)
		CarteNiveau.dessiner_drapeau(_zone, pied, 1.8)

	# Joueur, entouré d'un anneau pulsant.
	if is_instance_valid(_player):
		var p := _vers_carte(_player.global_position + Vector2(0, -40), rect)
		var anneau: Color = CarteNiveau.COULEUR_JOUEUR
		anneau.a = 0.4 + 0.5 * pulsation
		_zone.draw_arc(p, 12.0 + 3.0 * pulsation, 0.0, TAU, 32, anneau, 2.0, true)
		CarteNiveau.dessiner_joueur(_zone, p, _player.direction, 1.8)


func _texte_legende() -> String:
	var entrees := [
		[CarteNiveau.COULEUR_JOUEUR, "Joueur"],
		[CarteNiveau.COULEUR_DRAPEAU, "Drapeau (objectif)"],
		[CarteNiveau.COULEURS_ENNEMIS[Enemy.Comportement.TIREUR], "Tireur"],
		[CarteNiveau.COULEURS_ENNEMIS[Enemy.Comportement.KAMIKAZE], "Kamikaze"],
		[CarteNiveau.COULEURS_ENNEMIS[Enemy.Comportement.SENTINELLE], "Sentinelle"],
		[CarteNiveau.COULEUR_BUTIN, "Butin"],
	]
	var morceaux: PackedStringArray = []
	for entree in entrees:
		morceaux.append("[color=#%s]●[/color] %s" % [(entree[0] as Color).to_html(false), entree[1]])
	return "[center]%s[/center]" % "      ".join(morceaux)

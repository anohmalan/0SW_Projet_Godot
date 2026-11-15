class_name Minimap
extends Control

## Mini-carte ronde centrée sur le joueur. L'image du niveau (CarteNiveau) défile sous le
## joueur avec les marqueurs (ennemis, butins, vue, drapeau). Le disque est découpé par le
## shader masque_rond.

const SHADER_MASQUE := preload("res://shaders/masque_rond.gdshader")

const COULEUR_FOND := Color(0.02, 0.12, 0.11, 0.85)
const COULEUR_ANNEAU := Color(0.282, 0.663, 0.569, 1)

## Zoom : taille d'une tuile du niveau sur la mini-carte, en pixels.
@export var pixels_par_tuile := 1.6
@export var epaisseur_anneau := 3.0

var _carte: CarteNiveau
var _player: Player
var _materiau := ShaderMaterial.new()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_materiau.shader = SHADER_MASQUE
	material = _materiau
	resized.connect(_mettre_a_jour_masque)
	_mettre_a_jour_masque()
	set_process(false)


func configurer(carte: CarteNiveau, player: Player) -> void:
	_carte = carte
	_player = player
	set_process(true)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _centre() -> Vector2:
	return size * 0.5


func _rayon() -> float:
	return minf(size.x, size.y) * 0.5


func _mettre_a_jour_masque() -> void:
	_materiau.set_shader_parameter("centre", _centre())
	_materiau.set_shader_parameter("rayon", _rayon())
	queue_redraw()


## Position monde → position sur la mini-carte, le joueur étant au centre.
func _vers_minimap(position_monde: Vector2, origine_cases: Vector2) -> Vector2:
	return _centre() + (_carte.en_cases(position_monde) - origine_cases) * pixels_par_tuile


func _pret() -> bool:
	return _carte != null and _carte.est_valide() and is_instance_valid(_player)


# --- Dessin ------------------------------------------------------------------

func _draw() -> void:
	draw_circle(_centre(), _rayon(), COULEUR_FOND)
	if _pret():
		var origine: Vector2 = _carte.en_cases(_point_joueur())
		var coin: Vector2 = _centre() - origine * pixels_par_tuile
		var rect_image := Rect2(coin, Vector2(_carte.cases.size) * pixels_par_tuile)
		draw_texture_rect(_carte.texture, rect_image, false)
		draw_texture_rect(_carte.texture_brouillard, rect_image, false)
		_dessiner_vue(origine)
		_dessiner_marqueurs(origine)
		CarteNiveau.dessiner_joueur(self, _centre(), _player.direction)
	# L'anneau est tracé juste à l'intérieur du disque pour ne pas être coupé par le masque.
	draw_arc(_centre(), _rayon() - epaisseur_anneau * 0.5, 0.0, TAU, 64, COULEUR_ANNEAU, epaisseur_anneau, true)
	if _pret():
		# Par-dessus l'anneau : la flèche du drapeau hors champ s'y pose.
		_dessiner_drapeau(_carte.en_cases(_point_joueur()))


func _point_joueur() -> Vector2:
	return _player.global_position + Vector2(0, -40)


func _dessiner_marqueurs(origine: Vector2) -> void:
	# Brouillard : seuls les ennemis et butins des zones déjà explorées sont montrés.
	for butin in get_tree().get_nodes_in_group("butins"):
		if _carte.est_explore(butin.global_position):
			draw_circle(_vers_minimap(butin.global_position, origine), 2.0, CarteNiveau.COULEUR_BUTIN)
	for noeud in get_tree().get_nodes_in_group("ennemis"):
		var ennemi := noeud as Enemy
		if ennemi == null or ennemi.vie <= 0 or not _carte.est_explore(ennemi.global_position):
			continue
		draw_circle(_vers_minimap(ennemi.global_position, origine), 3.0, CarteNiveau.couleur_ennemi(ennemi))


## Objectif du niveau : icône si le drapeau est dans le disque, sinon flèche pulsante
## sur l'anneau, pointée dans sa direction.
func _dessiner_drapeau(origine: Vector2) -> void:
	var drapeau := get_tree().get_first_node_in_group(&"drapeau") as Node2D
	if drapeau == null:
		return
	var position_carte := _vers_minimap(drapeau.global_position, origine)
	var ecart := position_carte - _centre()
	var limite := _rayon() - epaisseur_anneau - 8.0
	if ecart.length() <= limite:
		CarteNiveau.dessiner_drapeau(self, position_carte)
		return
	var sens := ecart.normalized()
	var pointe := _centre() + sens * (_rayon() - 2.0)
	var pulsation := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 160.0)
	var couleur: Color = CarteNiveau.COULEUR_DRAPEAU
	couleur.a = pulsation
	var cote := sens.orthogonal() * 6.0
	var fleche := PackedVector2Array([pointe, pointe - sens * 11.0 + cote, pointe - sens * 11.0 - cote])
	draw_colored_polygon(fleche, couleur)
	draw_polyline(fleche + PackedVector2Array([fleche[0]]), Color(1, 1, 1, pulsation), 1.0)


## Cadre de ce que la caméra montre actuellement.
func _dessiner_vue(origine: Vector2) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var demi := get_viewport_rect().size / camera.zoom * 0.5
	var centre := camera.get_screen_center_position()
	var haut_gauche := _vers_minimap(centre - demi, origine)
	var bas_droite := _vers_minimap(centre + demi, origine)
	draw_rect(Rect2(haut_gauche, bas_droite - haut_gauche).abs(), CarteNiveau.COULEUR_VUE, false, 1.0)

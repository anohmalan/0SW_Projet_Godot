class_name Minimap
extends Control

## Mini-carte ronde centrée sur le joueur. L'image de la TileMapLayer (1 pixel par tuile) est
## construite une fois ; elle défile sous le joueur avec les marqueurs (ennemis, butins, vue).
## Le disque est découpé par le shader masque_rond.

const SHADER_MASQUE := preload("res://shaders/masque_rond.gdshader")

const COULEUR_FOND := Color(0.02, 0.12, 0.11, 0.85)
const COULEUR_ANNEAU := Color(0.282, 0.663, 0.569, 1)
const COULEUR_SOLIDE := Color(0.33, 0.78, 0.66, 0.95)
const COULEUR_DECOR := Color(0.1, 0.32, 0.28, 0.55)
const COULEUR_JOUEUR := Color("#00FFA8")
const COULEUR_BUTIN := Color("#FFE15A")
const COULEUR_VUE := Color(1.0, 1.0, 1.0, 0.4)
const COULEURS_ENNEMIS := {
	Enemy.Comportement.TIREUR: Color("#FF3355"),
	Enemy.Comportement.KAMIKAZE: Color("#FF8A2A"),
	Enemy.Comportement.SENTINELLE: Color("#B98CFF"),
}

## Zoom : taille d'une tuile du niveau sur la mini-carte, en pixels.
@export var pixels_par_tuile := 1.6
@export var epaisseur_anneau := 3.0

var _carte: TileMapLayer
var _player: Player
var _texture: ImageTexture
var _cases := Rect2i()
var _materiau := ShaderMaterial.new()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_materiau.shader = SHADER_MASQUE
	material = _materiau
	resized.connect(_mettre_a_jour_masque)
	_mettre_a_jour_masque()
	set_process(false)


func configurer(carte: TileMapLayer, player: Player) -> void:
	_carte = carte
	_player = player
	_construire_image()
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


# --- Image de la carte -------------------------------------------------------

func _construire_image() -> void:
	_cases = _carte.get_used_rect()
	if not _cases.has_area():
		return
	var image := Image.create(_cases.size.x, _cases.size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var a_physique := _carte.tile_set.get_physics_layers_count() > 0
	for cellule in _carte.get_used_cells():
		var donnees := _carte.get_cell_tile_data(cellule)
		var solide := a_physique and donnees != null and donnees.get_collision_polygons_count(0) > 0
		image.set_pixelv(cellule - _cases.position, COULEUR_SOLIDE if solide else COULEUR_DECOR)
	_texture = ImageTexture.create_from_image(image)


## Position monde → position en cases, relative au coin de l'image.
func _en_cases(position_monde: Vector2) -> Vector2:
	return _carte.to_local(position_monde) / Vector2(_carte.tile_set.tile_size) - Vector2(_cases.position)


## Position monde → position sur la mini-carte, le joueur étant au centre.
func _vers_minimap(position_monde: Vector2, origine_cases: Vector2) -> Vector2:
	return _centre() + (_en_cases(position_monde) - origine_cases) * pixels_par_tuile


# --- Dessin ------------------------------------------------------------------

func _draw() -> void:
	draw_circle(_centre(), _rayon(), COULEUR_FOND)
	if _texture != null and is_instance_valid(_carte) and is_instance_valid(_player):
		var origine := _en_cases(_point_joueur())
		var coin := _centre() - origine * pixels_par_tuile
		draw_texture_rect(_texture, Rect2(coin, Vector2(_cases.size) * pixels_par_tuile), false)
		_dessiner_vue(origine)
		_dessiner_marqueurs(origine)
		_dessiner_joueur()
	# L'anneau est tracé juste à l'intérieur du disque pour ne pas être coupé par le masque.
	draw_arc(_centre(), _rayon() - epaisseur_anneau * 0.5, 0.0, TAU, 64, COULEUR_ANNEAU, epaisseur_anneau, true)


func _point_joueur() -> Vector2:
	return _player.global_position + Vector2(0, -40)


func _dessiner_marqueurs(origine: Vector2) -> void:
	for butin in get_tree().get_nodes_in_group("butins"):
		draw_circle(_vers_minimap(butin.global_position, origine), 2.0, COULEUR_BUTIN)
	for noeud in get_tree().get_nodes_in_group("ennemis"):
		var ennemi := noeud as Enemy
		if ennemi == null or ennemi.vie <= 0:
			continue
		var couleur: Color = COULEURS_ENNEMIS.get(ennemi.comportement, Color.RED)
		draw_circle(_vers_minimap(ennemi.global_position, origine), 3.0, couleur)


func _dessiner_joueur() -> void:
	var centre := _centre()
	var d := float(_player.direction)
	# Flèche pointée dans le sens où regarde le joueur.
	var fleche := PackedVector2Array([
		centre + Vector2(6.0 * d, 0.0),
		centre + Vector2(-4.0 * d, -4.5),
		centre + Vector2(-4.0 * d, 4.5),
	])
	draw_colored_polygon(fleche, COULEUR_JOUEUR)
	draw_polyline(fleche + PackedVector2Array([fleche[0]]), Color(0, 0, 0, 0.8), 1.0)


## Cadre de ce que la caméra montre actuellement.
func _dessiner_vue(origine: Vector2) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var demi := get_viewport_rect().size / camera.zoom * 0.5
	var centre := camera.get_screen_center_position()
	var haut_gauche := _vers_minimap(centre - demi, origine)
	var bas_droite := _vers_minimap(centre + demi, origine)
	draw_rect(Rect2(haut_gauche, bas_droite - haut_gauche).abs(), COULEUR_VUE, false, 1.0)

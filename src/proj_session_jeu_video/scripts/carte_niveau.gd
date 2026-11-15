class_name CarteNiveau
extends RefCounted

## Image d'un niveau (1 pixel par tuile) construite une seule fois à partir de sa TileMapLayer,
## partagée par la mini-carte et la grande carte. Fournit aussi la conversion monde → cases,
## les couleurs et le dessin des icônes communes.

const COULEUR_SOLIDE := Color(0.33, 0.78, 0.66, 0.95)
const COULEUR_DECOR := Color(0.1, 0.32, 0.28, 0.55)
const COULEUR_JOUEUR := Color("#00FFA8")
const COULEUR_BUTIN := Color("#FFE15A")
const COULEUR_VUE := Color(1.0, 1.0, 1.0, 0.4)
const COULEUR_DRAPEAU := Drapeau.COULEUR
const COULEURS_ENNEMIS := {
	Enemy.Comportement.TIREUR: Color("#FF3355"),
	Enemy.Comportement.KAMIKAZE: Color("#FF8A2A"),
	Enemy.Comportement.SENTINELLE: Color("#B98CFF"),
}

var calque: TileMapLayer
var texture: ImageTexture
var cases := Rect2i()


func _init(p_calque: TileMapLayer) -> void:
	calque = p_calque
	_construire()


func est_valide() -> bool:
	return texture != null and is_instance_valid(calque)


## Position monde → position en cases, relative au coin de l'image.
func en_cases(position_monde: Vector2) -> Vector2:
	return calque.to_local(position_monde) / Vector2(calque.tile_set.tile_size) - Vector2(cases.position)


func _construire() -> void:
	cases = calque.get_used_rect()
	if not cases.has_area():
		return
	var image := Image.create(cases.size.x, cases.size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var a_physique := calque.tile_set.get_physics_layers_count() > 0
	for cellule in calque.get_used_cells():
		var donnees := calque.get_cell_tile_data(cellule)
		var solide := a_physique and donnees != null and donnees.get_collision_polygons_count(0) > 0
		image.set_pixelv(cellule - cases.position, COULEUR_SOLIDE if solide else COULEUR_DECOR)
	texture = ImageTexture.create_from_image(image)


# --- Icônes communes ---------------------------------------------------------

static func couleur_ennemi(ennemi: Enemy) -> Color:
	return COULEURS_ENNEMIS.get(ennemi.comportement, Color.RED)


## Flèche du joueur, pointée dans le sens où il regarde.
static func dessiner_joueur(toile: CanvasItem, centre: Vector2, direction: int, taille: float = 1.0) -> void:
	var d := float(direction)
	var fleche := PackedVector2Array([
		centre + Vector2(6.0 * d, 0.0) * taille,
		centre + Vector2(-4.0 * d, -4.5) * taille,
		centre + Vector2(-4.0 * d, 4.5) * taille,
	])
	toile.draw_colored_polygon(fleche, COULEUR_JOUEUR)
	toile.draw_polyline(fleche + PackedVector2Array([fleche[0]]), Color(0, 0, 0, 0.8), 1.0)


static func dessiner_drapeau(toile: CanvasItem, pied: Vector2, taille: float = 1.0) -> void:
	var sommet := pied + Vector2(0, -12) * taille
	toile.draw_line(pied, sommet, Color(0.9, 0.95, 0.95), 1.5 * taille)
	toile.draw_colored_polygon(PackedVector2Array([
		sommet, sommet + Vector2(8, 3) * taille, sommet + Vector2(0, 6) * taille]), COULEUR_DRAPEAU)
	toile.draw_circle(pied, 1.5 * taille, Color.WHITE)

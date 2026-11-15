class_name CarteNiveau
extends RefCounted

## Image d'un niveau (1 pixel par tuile) construite une seule fois à partir de sa TileMapLayer,
## partagée par la mini-carte et la grande carte. Fournit aussi la conversion monde → cases,
## les couleurs, le dessin des icônes communes et le brouillard de guerre (zones explorées).

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

const COULEUR_BROUILLARD := Color(0.01, 0.05, 0.045, 0.94)

var calque: TileMapLayer
var texture: ImageTexture
var cases := Rect2i()

## Brouillard : opaque sur les cases jamais vues, transparent sur les cases explorées.
var texture_brouillard: ImageTexture
var _brouillard: Image
var _explore := PackedByteArray()
var _brouillard_modifie := false


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

	_brouillard = Image.create(cases.size.x, cases.size.y, false, Image.FORMAT_RGBA8)
	_brouillard.fill(COULEUR_BROUILLARD)
	_explore.resize(cases.size.x * cases.size.y)
	_explore.fill(0)
	texture_brouillard = ImageTexture.create_from_image(_brouillard)


# --- Brouillard de guerre ----------------------------------------------------

## Marque comme explorées toutes les cases couvertes par un rectangle du monde
## (typiquement la zone affichée par la caméra).
func reveler(zone_monde: Rect2) -> void:
	if _brouillard == null:
		return
	var a := en_cases(zone_monde.position)
	var b := en_cases(zone_monde.end)
	var debut := Vector2i(clampi(floori(minf(a.x, b.x)), 0, cases.size.x), clampi(floori(minf(a.y, b.y)), 0, cases.size.y))
	var fin := Vector2i(clampi(ceili(maxf(a.x, b.x)), 0, cases.size.x), clampi(ceili(maxf(a.y, b.y)), 0, cases.size.y))
	for y in range(debut.y, fin.y):
		for x in range(debut.x, fin.x):
			var index := y * cases.size.x + x
			if _explore[index] == 0:
				_explore[index] = 1
				_brouillard.set_pixel(x, y, Color.TRANSPARENT)
				_brouillard_modifie = true


func reveler_tout() -> void:
	if _brouillard == null:
		return
	_explore.fill(1)
	_brouillard.fill(Color.TRANSPARENT)
	_brouillard_modifie = true


## Envoie les cases nouvellement explorées à la texture (une fois par mise à jour, pas par case).
func appliquer_brouillard() -> void:
	if _brouillard_modifie:
		texture_brouillard.update(_brouillard)
		_brouillard_modifie = false


func est_explore(position_monde: Vector2) -> bool:
	if _brouillard == null:
		return true
	var c := Vector2i(en_cases(position_monde).floor())
	if c.x < 0 or c.y < 0 or c.x >= cases.size.x or c.y >= cases.size.y:
		return false
	return _explore[c.y * cases.size.x + c.x] == 1


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

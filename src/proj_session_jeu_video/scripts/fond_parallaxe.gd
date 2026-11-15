@tool
class_name FondParallaxe
extends Control

## Arrière-plan en parallaxe : l'image défile moins vite que le niveau (impression de
## profondeur). Elle se répète à l'horizontale et reste toujours dans l'écran à la verticale,
## sans jamais laisser de bord vide.
## Dans l'éditeur, un aperçu est dessiné derrière le niveau (zone_apercu), à la même taille
## qu'en jeu : il est indicatif, car en jeu le fond suit la caméra.

@export var texture: Texture2D:
	set(valeur):
		texture = valeur
		queue_redraw()
## Part du mouvement de la caméra suivie par le fond (0 = fixe, 1 = colle au niveau).
@export_range(0.0, 1.0) var facteur_horizontal := 0.2
@export_range(0.0, 1.0) var facteur_vertical := 0.08
## Agrandissement au-delà de la taille d'écran : la marge permet le défilement vertical.
@export var marge_verticale := 1.25:
	set(valeur):
		marge_verticale = valeur
		queue_redraw()

## Retourne une copie sur deux en miroir : masque les raccords d'une image qui ne se répète pas.
@export var miroir_alterne := true:
	set(valeur):
		miroir_alterne = valeur
		queue_redraw()

@export_group("Aperçu dans l'éditeur")
## Zone du niveau (coordonnées du monde) couverte par l'aperçu dans l'éditeur.
@export var zone_apercu := Rect2(-400, -1250, 3500, 2350):
	set(valeur):
		zone_apercu = valeur
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		queue_redraw()


## Taille de l'image agrandie pour couvrir un écran donné.
func _taille_image(ecran: Vector2) -> Vector2:
	var taille_image := Vector2(texture.get_size())
	var echelle := maxf(ecran.x / taille_image.x, ecran.y * marge_verticale / taille_image.y)
	return taille_image * echelle


func _draw() -> void:
	if texture == null:
		return
	if Engine.is_editor_hint():
		_dessiner_apercu()
		return
	var ecran := size
	var taille := _taille_image(ecran)

	var camera := get_viewport().get_camera_2d()
	var centre := camera.get_screen_center_position() if camera != null else Vector2.ZERO

	# Vertical : décalage autour du milieu des limites de la caméra, borné pour rester à l'écran.
	var milieu_y := 0.0
	if camera != null:
		milieu_y = (camera.limit_top + camera.limit_bottom) * 0.5
	var marge := taille.y - ecran.y
	var y := clampf(-marge * 0.5 - (centre.y - milieu_y) * facteur_vertical, -marge, 0.0)

	# Horizontal : défilement ralenti, image répétée autant que nécessaire.
	var defilement := centre.x * facteur_horizontal
	var premiere := floori(defilement / taille.x)
	_dessiner_rangee(premiere * taille.x - defilement, y, taille, premiere, ecran.x)


## Dans l'éditeur, le CanvasLayer est affiché dans le repère du monde : on répète l'image
## sur la largeur de zone_apercu, centrée verticalement sur la zone.
func _dessiner_apercu() -> void:
	var ecran := Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width", 1152),
		ProjectSettings.get_setting("display/window/size/viewport_height", 648))
	var taille := _taille_image(ecran)
	var y := zone_apercu.get_center().y - taille.y * 0.5
	_dessiner_rangee(zone_apercu.position.x, y, taille, 0, zone_apercu.end.x)


## Dessine des copies côte à côte depuis x jusqu'à x_fin ; avec miroir_alterne, les copies
## d'indice impair sont retournées pour que chaque raccord relie deux bords identiques.
func _dessiner_rangee(x: float, y: float, taille: Vector2, indice: int, x_fin: float) -> void:
	while x < x_fin:
		if miroir_alterne and posmod(indice, 2) == 1:
			draw_set_transform(Vector2(x + taille.x, y), 0.0, Vector2(-1.0, 1.0))
			draw_texture_rect(texture, Rect2(Vector2.ZERO, taille), false)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_texture_rect(texture, Rect2(Vector2(x, y), taille), false)
		x += taille.x
		indice += 1

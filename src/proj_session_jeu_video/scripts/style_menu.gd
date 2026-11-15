class_name StyleMenu
extends RefCounted

## Style néon commun aux boutons des menus en jeu (pause, victoire…).

const COULEUR_TEXTE := Color("#F1F5DF")
const COULEUR_CONTOUR_TEXTE := Color("#073A32")
const COULEUR_FOND := Color("#073A35")
const COULEUR_SURVOL := Color("#10574B")
const COULEUR_APPUI := Color("#0B4037")
const COULEUR_FOCUS := Color("#00D995")
const COULEUR_BORDURE := Color("#48A991")


static func styliser_bouton(bouton: Button, taille_police: int = 22, largeur_min: float = 260.0) -> void:
	bouton.focus_mode = Control.FOCUS_ALL
	bouton.custom_minimum_size.x = largeur_min
	bouton.add_theme_font_size_override("font_size", taille_police)
	bouton.add_theme_color_override("font_color", COULEUR_TEXTE)
	bouton.add_theme_color_override("font_hover_color", Color.WHITE)
	bouton.add_theme_color_override("font_focus_color", Color.WHITE)
	bouton.add_theme_color_override("font_pressed_color", Color.WHITE)
	bouton.add_theme_color_override("font_outline_color", COULEUR_CONTOUR_TEXTE)
	bouton.add_theme_constant_override("outline_size", 2)
	bouton.add_theme_stylebox_override("normal", style(COULEUR_FOND, COULEUR_BORDURE, false))
	bouton.add_theme_stylebox_override("hover", style(COULEUR_SURVOL, COULEUR_BORDURE, true))
	bouton.add_theme_stylebox_override("pressed", style(COULEUR_APPUI, COULEUR_BORDURE, false))
	bouton.add_theme_stylebox_override("focus", style(COULEUR_FOCUS, Color.WHITE, true))


static func style(fond: Color, bordure: Color, illumine: bool) -> StyleBoxFlat:
	var resultat := StyleBoxFlat.new()
	resultat.bg_color = fond
	resultat.border_color = bordure
	resultat.set_border_width_all(2)
	resultat.corner_radius_top_left = 16
	resultat.corner_radius_top_right = 8
	resultat.corner_radius_bottom_right = 16
	resultat.corner_radius_bottom_left = 8
	resultat.content_margin_left = 22
	resultat.content_margin_right = 22
	resultat.content_margin_top = 14
	resultat.content_margin_bottom = 14
	if illumine:
		resultat.shadow_color = Color(0.0, 1.0, 0.62, 0.72)
		resultat.shadow_size = 20
	return resultat


## Navigation en boucle de haut en bas entre des boutons empilés.
static func chainer_focus_vertical(boutons: Array[Button]) -> void:
	for i in boutons.size():
		var bouton := boutons[i]
		var precedent := boutons[posmod(i - 1, boutons.size())]
		var suivant := boutons[(i + 1) % boutons.size()]
		bouton.focus_neighbor_top = bouton.get_path_to(precedent)
		bouton.focus_neighbor_bottom = bouton.get_path_to(suivant)
		bouton.focus_previous = bouton.get_path_to(precedent)
		bouton.focus_next = bouton.get_path_to(suivant)
		bouton.focus_neighbor_left = bouton.get_path()
		bouton.focus_neighbor_right = bouton.get_path()

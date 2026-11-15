extends Control

## Écran « Choisir un niveau » : une carte par niveau, avec un aperçu en direct de sa carte.
## Pour ajouter un niveau, il suffit d'ajouter une entrée dans NIVEAUX.

const SCENE_MENU_PRINCIPAL := "res://scenes/menu_principal.tscn"

const NIVEAUX := [
	{
		"nom": "NIVEAU 1",
		"sous_titre": "Jungle industrielle néon",
		"scene": "res://scenes/niveau_1/niveau_1.tscn",
		"apercu": "res://scenes/niveau_1/world_niveau_1.tscn",
	},
	{
		"nom": "NIVEAU 2",
		"sous_titre": "Bientôt disponible",
		"scene": "",
		"apercu": "",
	},
]

const TAILLE_APERCU := Vector2(320, 180)
const COULEUR_TEXTE := Color("#F1F5DF")
const COULEUR_ACCENT := Color("#00D995")
const COULEUR_FOND := Color("#073A35")
const COULEUR_BORDURE := Color("#48A991")

@onready var _cartes: HBoxContainer = %Cartes
@onready var _retour: Button = %Retour
@onready var _statut: Label = %Statut

var _en_transition := false


func _ready() -> void:
	var premiere: Button = null
	for niveau in NIVEAUX:
		var carte := _creer_carte(niveau)
		_cartes.add_child(carte)
		if premiere == null and not carte.disabled:
			premiere = carte
	_styliser_retour()
	_retour.pressed.connect(_retour_menu)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	if premiere != null:
		premiere.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("retour") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_retour_menu()


func _lancer_niveau(chemin: String) -> void:
	if _en_transition:
		return
	_en_transition = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void:
		var erreur := get_tree().change_scene_to_file(chemin)
		if erreur != OK:
			_en_transition = false
			modulate.a = 1.0
			_statut.text = "Impossible d'ouvrir le niveau : " + error_string(erreur)
			push_error("%s — %s" % [_statut.text, chemin]))


func _retour_menu() -> void:
	if _en_transition:
		return
	get_tree().change_scene_to_file(SCENE_MENU_PRINCIPAL)


# --- Cartes ------------------------------------------------------------------

func _creer_carte(niveau: Dictionary) -> Button:
	var disponible: bool = not String(niveau["scene"]).is_empty()
	var carte := Button.new()
	carte.custom_minimum_size = TAILLE_APERCU + Vector2(28, 110)
	carte.focus_mode = Control.FOCUS_ALL if disponible else Control.FOCUS_NONE
	carte.disabled = not disponible
	carte.add_theme_stylebox_override("normal", _style_carte(COULEUR_FOND, COULEUR_BORDURE, false))
	carte.add_theme_stylebox_override("hover", _style_carte(Color("#10574B"), COULEUR_BORDURE, true))
	carte.add_theme_stylebox_override("pressed", _style_carte(Color("#0B4037"), COULEUR_BORDURE, false))
	carte.add_theme_stylebox_override("focus", _style_carte(Color("#0E6B57"), Color.WHITE, true))
	carte.add_theme_stylebox_override("disabled", _style_carte(Color(0.02, 0.12, 0.11, 0.8), Color(0.2, 0.35, 0.32), false))
	if disponible:
		carte.pressed.connect(_lancer_niveau.bind(niveau["scene"]))

	var contenu := VBoxContainer.new()
	contenu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	contenu.add_theme_constant_override("separation", 8)
	contenu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carte.add_child(contenu)

	contenu.add_child(_creer_apercu(String(niveau["apercu"])))
	var nom := _etiquette(niveau["nom"], 24, COULEUR_ACCENT if disponible else Color(0.45, 0.6, 0.56))
	contenu.add_child(nom)
	var sous_titre := _etiquette(niveau["sous_titre"], 17, COULEUR_TEXTE if disponible else Color(0.55, 0.62, 0.6))
	contenu.add_child(sous_titre)
	return carte


## Aperçu en direct : la scène du monde rendue dans un SubViewport, cadrée sur ses tuiles.
func _creer_apercu(chemin: String) -> Control:
	if chemin.is_empty() or not ResourceLoader.exists(chemin):
		var verrou := _etiquette("VERROUILLÉ", 22, Color(0.45, 0.6, 0.56))
		verrou.custom_minimum_size = TAILLE_APERCU
		verrou.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		verrou.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		return verrou

	var conteneur := SubViewportContainer.new()
	conteneur.custom_minimum_size = TAILLE_APERCU
	conteneur.stretch = true
	conteneur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vue := SubViewport.new()
	vue.size = Vector2i(TAILLE_APERCU)
	vue.transparent_bg = false
	conteneur.add_child(vue)

	var monde: Node2D = (load(chemin) as PackedScene).instantiate()
	vue.add_child(monde)
	var camera := Camera2D.new()
	vue.add_child(camera)
	# Les positions globales des tuiles ne sont connues qu'une fois la carte dans l'arbre.
	_cadrer.call_deferred(monde, camera)
	return conteneur


func _cadrer(monde: Node2D, camera: Camera2D) -> void:
	var zone := _zone_tuiles(monde)
	if not zone.has_area():
		return
	camera.position = zone.get_center()
	var echelle := minf(TAILLE_APERCU.x / zone.size.x, TAILLE_APERCU.y / zone.size.y)
	camera.zoom = Vector2.ONE * echelle
	camera.reset_smoothing()


func _zone_tuiles(monde: Node) -> Rect2:
	var zone := Rect2()
	for carte in monde.find_children("*", "TileMapLayer", true, false):
		var calque := carte as TileMapLayer
		var cases := calque.get_used_rect()
		if not cases.has_area():
			continue
		var demi := Vector2(calque.tile_set.tile_size) * 0.5
		var debut := calque.to_global(calque.map_to_local(cases.position) - demi)
		var fin := calque.to_global(calque.map_to_local(cases.end) - demi)
		var rect := Rect2(debut, fin - debut).abs()
		zone = rect if not zone.has_area() else zone.merge(rect)
	return zone


# --- Style -------------------------------------------------------------------

func _etiquette(texte: String, taille: int, couleur: Color) -> Label:
	var etiquette := Label.new()
	etiquette.text = texte
	etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiquette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiquette.add_theme_font_size_override("font_size", taille)
	etiquette.add_theme_color_override("font_color", couleur)
	etiquette.add_theme_color_override("font_outline_color", Color("#073A32"))
	etiquette.add_theme_constant_override("outline_size", 3)
	return etiquette


func _styliser_retour() -> void:
	_retour.focus_mode = Control.FOCUS_ALL
	_retour.add_theme_font_size_override("font_size", 20)
	_retour.add_theme_color_override("font_color", COULEUR_TEXTE)
	_retour.add_theme_color_override("font_hover_color", Color.WHITE)
	_retour.add_theme_color_override("font_focus_color", Color.WHITE)
	_retour.add_theme_stylebox_override("normal", _style_carte(COULEUR_FOND, COULEUR_BORDURE, false))
	_retour.add_theme_stylebox_override("hover", _style_carte(Color("#10574B"), COULEUR_BORDURE, true))
	_retour.add_theme_stylebox_override("pressed", _style_carte(Color("#0B4037"), COULEUR_BORDURE, false))
	_retour.add_theme_stylebox_override("focus", _style_carte(COULEUR_ACCENT, Color.WHITE, true))


func _style_carte(fond: Color, bordure: Color, illumine: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fond
	style.border_color = bordure
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	if illumine:
		style.shadow_color = Color(0.0, 1.0, 0.62, 0.6)
		style.shadow_size = 16
	return style

extends Node2D

## Identifiant du niveau dans la progression sauvegardée (doit correspondre à l'écran de choix).
@export var identifiant := "niveau_1"
## Piste de assets/audio/musique jouée pendant le niveau.
@export var piste_musique := "niveau_1"
## Ambiance de assets/audio/ambiance jouée sous la musique (vide : aucune).
@export var piste_ambiance := "jungle_insectes"
## Ajuste le zoom pour qu'un pixel du tileset fasse un nombre entier de pixels à l'écran
## (pixel art net, sans pixels de tailles irrégulières).
@export var pixels_nets := true
## Cartes masquées tant que le joueur n'a pas vu les zones (mini-map et grande carte).
@export var brouillard_de_guerre := true
## Intervalle entre deux mises à jour des zones explorées, en secondes.
@export var intervalle_exploration := 0.15

const MARGE_EXPLORATION := 32.0 # pixels ajoutés autour de ce que montre la caméra

@onready var player: Player = $Player
@onready var pool_balles: PoolBalles = $PoolBalles
@onready var pool_orbes: PoolBalles = $PoolOrbes
@onready var conteneur_ennemis: Node2D = $Ennemis
@onready var carte: TileMapLayer = $WorldNiveau1/TileMapLayer
@onready var hud: HUD = $HUD
@onready var drapeau: Drapeau = $Drapeau
@onready var ecran_fin: EcranVictoire = $EcranVictoire
@onready var grande_carte: GrandeCarte = $GrandeCarte

# Statistiques affichées à la fin du niveau.
var _temps_niveau := 0.0
var _ennemis_vaincus := 0
var _morts := 0

var _carte_niveau: CarteNiveau
var _attente_exploration := 0.0


func _ready() -> void:
	Audio.musique(piste_musique)
	Audio.ambiance(piste_ambiance)
	player.tir_demande.connect(_on_tir_demande)
	player.est_mort.connect(_on_player_est_mort)
	player.camera.limiter(_zone_camera())
	if pixels_nets:
		_ajuster_zoom_pixels_nets()
	hud.brancher(player)
	# Une seule image du niveau, partagée par la mini-carte et la grande carte.
	_carte_niveau = CarteNiveau.new(carte)
	hud.minimap.configurer(_carte_niveau, player)
	grande_carte.configurer(_carte_niveau, player)
	if not brouillard_de_guerre:
		_carte_niveau.reveler_tout()
		_carte_niveau.appliquer_brouillard()
	else:
		# La caméra n'est placée qu'après la première image : on révèle le départ juste après.
		_explorer.call_deferred()
	drapeau.atteint.connect(_on_drapeau_atteint)
	for ennemi in conteneur_ennemis.get_children():
		if ennemi is Enemy:
			_brancher_ennemi(ennemi)


func _exit_tree() -> void:
	# L'ambiance appartient au niveau : elle s'éteint quand on le quitte.
	Audio.arreter_ambiance()


func _process(delta: float) -> void:
	# Le compteur s'arrête de lui-même pendant la pause (nœud pausable).
	_temps_niveau += delta
	if brouillard_de_guerre:
		_attente_exploration -= delta
		if _attente_exploration <= 0.0:
			_attente_exploration = intervalle_exploration
			_explorer()


## Révèle sur les cartes tout ce que la caméra montre en ce moment.
func _explorer() -> void:
	var camera := player.camera
	var demi := get_viewport_rect().size / camera.zoom * 0.5 + Vector2.ONE * MARGE_EXPLORATION
	var centre := camera.get_screen_center_position()
	_carte_niveau.reveler(Rect2(centre - demi, demi * 2.0))
	_carte_niveau.appliquer_brouillard()


## Le monde est agrandi (ex. ×1,1) : on compense par le zoom de la caméra pour obtenir un
## rapport entier entre pixels du tileset et pixels de l'écran. Le placement ne change pas.
func _ajuster_zoom_pixels_nets() -> void:
	var echelle_monde := carte.get_global_transform().get_scale().x
	if echelle_monde <= 0.0:
		return
	var rapport_entier := maxf(1.0, roundf(echelle_monde))
	player.camera.zoom = Vector2.ONE * (rapport_entier / echelle_monde)


## Zone que la caméra peut montrer : les tuiles du niveau, plus le drapeau (mât et halo
## compris), qui peut dépasser au-dessus des tuiles les plus hautes.
func _zone_camera() -> Rect2:
	return _zone_du_niveau().merge(drapeau.zone_visible())


## Rectangle (coordonnées globales) couvert par les tuiles peintes du niveau.
func _zone_du_niveau() -> Rect2:
	var cases := carte.get_used_rect()
	var demi_tuile := Vector2(carte.tile_set.tile_size) * 0.5
	var debut := carte.to_global(carte.map_to_local(cases.position) - demi_tuile)
	var fin := carte.to_global(carte.map_to_local(cases.end) - demi_tuile)
	return Rect2(debut, fin - debut)


func _brancher_ennemi(ennemi: Enemy) -> void:
	ennemi.tir_demande.connect(_on_tir_ennemi)
	ennemi.est_mort.connect(func() -> void: _ennemis_vaincus += 1)


func _on_tir_demande(position_tir: Vector2, direction: Vector2, arme: Arme) -> void:
	pool_balles.tirer(position_tir, direction, arme, true)


func _on_tir_ennemi(position_tir: Vector2, direction: Vector2, arme: Arme) -> void:
	pool_orbes.tirer(position_tir, direction, arme, false)


func _on_drapeau_atteint() -> void:
	var records: Dictionary = Progression.enregistrer_victoire(identifiant, _temps_niveau, _morts, _ennemis_vaincus)
	ecran_fin.afficher(_temps_niveau, _ennemis_vaincus, _morts, true, records)


## Chaque mort coûte un cœur. S'il en reste, le joueur réapparaît là où il se tenait en
## dernier sur le décor ; le niveau (ennemis, butins) reste tel quel. Sinon : Game Over.
func _on_player_est_mort() -> void:
	_morts += 1
	var restants := player.sante.perdre_coeur()
	if restants <= 0:
		ecran_fin.afficher(_temps_niveau, _ennemis_vaincus, _morts, false)
		return
	pool_balles.tout_desactiver()
	pool_orbes.tout_desactiver()
	player.reapparaitre(player.derniere_position_sure)
	Audio.jouer("coeur_perdu")
	hud.afficher_message("Cœur perdu — %d restant%s" % [restants, "s" if restants > 1 else ""])

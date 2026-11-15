extends Node2D

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


func _ready() -> void:
	player.tir_demande.connect(_on_tir_demande)
	player.est_mort.connect(_on_player_est_mort)
	player.camera.limiter(_zone_camera())
	hud.brancher(player)
	# Une seule image du niveau, partagée par la mini-carte et la grande carte.
	var carte_niveau: CarteNiveau = CarteNiveau.new(carte)
	hud.minimap.configurer(carte_niveau, player)
	grande_carte.configurer(carte_niveau, player)
	drapeau.atteint.connect(_on_drapeau_atteint)
	for ennemi in conteneur_ennemis.get_children():
		if ennemi is Enemy:
			_brancher_ennemi(ennemi)


func _process(delta: float) -> void:
	# Le compteur s'arrête de lui-même pendant la pause (nœud pausable).
	_temps_niveau += delta


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
	ecran_fin.afficher(_temps_niveau, _ennemis_vaincus, _morts, true)


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
	hud.afficher_message("Cœur perdu — %d restant%s" % [restants, "s" if restants > 1 else ""])

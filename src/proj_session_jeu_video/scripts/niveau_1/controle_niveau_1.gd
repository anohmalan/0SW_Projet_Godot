extends Node2D

@onready var player: Player = $Player
@onready var pool_balles: PoolBalles = $PoolBalles
@onready var pool_orbes: PoolBalles = $PoolOrbes
@onready var conteneur_ennemis: Node2D = $Ennemis
@onready var carte: TileMapLayer = $WorldNiveau1/TileMapLayer
@onready var hud: HUD = $HUD

var _position_depart := Vector2.ZERO
## Copies hors de l'arbre des ennemis tels que placés dans l'éditeur.
var _modeles_ennemis: Array[Enemy] = []


func _ready() -> void:
	_position_depart = player.global_position
	player.tir_demande.connect(_on_tir_demande)
	player.est_mort.connect(_on_player_est_mort)
	player.camera.limiter(_zone_du_niveau())
	hud.brancher(player)
	hud.minimap.configurer(carte, player)
	for ennemi in conteneur_ennemis.get_children():
		if ennemi is Enemy:
			_modeles_ennemis.append(ennemi.duplicate())
			_brancher_ennemi(ennemi)


## Rectangle (coordonnées globales) couvert par les tuiles peintes du niveau.
func _zone_du_niveau() -> Rect2:
	var cases := carte.get_used_rect()
	var demi_tuile := Vector2(carte.tile_set.tile_size) * 0.5
	var debut := carte.to_global(carte.map_to_local(cases.position) - demi_tuile)
	var fin := carte.to_global(carte.map_to_local(cases.end) - demi_tuile)
	return Rect2(debut, fin - debut)


func _exit_tree() -> void:
	for modele in _modeles_ennemis:
		modele.free()
	_modeles_ennemis.clear()


func _brancher_ennemi(ennemi: Enemy) -> void:
	ennemi.tir_demande.connect(_on_tir_ennemi)


func _on_tir_demande(position_tir: Vector2, direction: Vector2, arme: Arme) -> void:
	pool_balles.tirer(position_tir, direction, arme, true)


func _on_tir_ennemi(position_tir: Vector2, direction: Vector2, arme: Arme) -> void:
	pool_orbes.tirer(position_tir, direction, arme, false)


func _on_player_est_mort() -> void:
	player.reapparaitre(_position_depart)
	_reinitialiser_ennemis()


## Le niveau repart de zéro : balles effacées, ennemis replacés et soignés.
## Les butins, lâchés dans le même conteneur que les ennemis, disparaissent aussi.
func _reinitialiser_ennemis() -> void:
	pool_balles.tout_desactiver()
	pool_orbes.tout_desactiver()
	for ennemi in conteneur_ennemis.get_children():
		conteneur_ennemis.remove_child(ennemi)
		ennemi.queue_free()
	for modele in _modeles_ennemis:
		var ennemi: Enemy = modele.duplicate()
		conteneur_ennemis.add_child(ennemi)
		_brancher_ennemi(ennemi)

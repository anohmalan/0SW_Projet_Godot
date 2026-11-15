extends Node2D

@onready var player: Player = $Player
@onready var pool_balles: PoolBalles = $PoolBalles

var _position_depart := Vector2.ZERO


func _ready() -> void:
	_position_depart = player.global_position
	player.tir_demande.connect(_on_tir_demande)
	player.est_mort.connect(_on_player_est_mort)
	for ennemi in get_tree().get_nodes_in_group("ennemis"):
		ennemi.tir_demande.connect(_on_tir_ennemi)


func _on_tir_demande(position_tir: Vector2, direction: Vector2, arme: Arme) -> void:
	pool_balles.tirer(position_tir, direction, arme, true)


func _on_tir_ennemi(position_tir: Vector2, direction: Vector2, arme: Arme) -> void:
	pool_balles.tirer(position_tir, direction, arme, false)


func _on_player_est_mort() -> void:
	print("[RESPAWN] signal reçu; position initiale=", _position_depart)
	player.reapparaitre(_position_depart)
	print("[RESPAWN] position du Player=", player.global_position)

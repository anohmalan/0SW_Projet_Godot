class_name ViePlayer
extends Node

@export var vie_max := 100
@export var duree_invincible := 1.2

var vie := 100
var invincible := 0.0
var _player: Player


func initialiser(player: Player) -> void:
	_player = player
	vie = vie_max


func recevoir_degats(quantite: int, origine_x: float = INF) -> void:
	if vie == 0 or invincible > 0.0:
		return
	vie = maxi(vie - quantite, 0)
	_player.vie_changee.emit(vie, vie_max)
	if vie == 0:
		_player.state_machine.change_state(&"PlayerDead")
		return
	var sens := float(-_player.direction)
	if origine_x != INF:
		sens = 1.0 if _player.global_position.x >= origine_x else -1.0
	_player.velocity = Vector2(sens * 200.0, -220.0)
	_player.state_machine.change_state(&"PlayerHurt")


func update(delta: float) -> void:
	if invincible > 0.0:
		invincible -= delta
		_player.visuel.modulate.a = 0.35 if int(invincible * 12.0) % 2 == 0 else 1.0
		if invincible <= 0.0:
			_player.visuel.modulate.a = 1.0


func activer_invincibilite() -> void:
	invincible = duree_invincible


func arreter_invincibilite() -> void:
	invincible = 0.0
	_player.visuel.modulate.a = 1.0

class_name PlayerDead
extends BaseState

@export var player: Player
var _mort_signalee := false

func enter() -> void:
	_mort_signalee = false
	player.velocity.x = 0.0
	player.sante.arreter_invincibilite()
	player.visuel.animation_terminee.connect(_sur_animation_terminee)
	player.visuel.jouer("Dead", true)

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func physics_update(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.vitesse * 4.0 * delta)

func update(_delta: float) -> void:
	pass

func exit() -> void:
	player.visuel.animation_terminee.disconnect(_sur_animation_terminee)

func _sur_animation_terminee(nom: String) -> void:
	if nom == "Dead" and not _mort_signalee:
		_mort_signalee = true
		player.est_mort.emit()

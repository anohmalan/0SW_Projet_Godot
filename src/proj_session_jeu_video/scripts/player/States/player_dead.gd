class_name PlayerDead
extends BaseState

@export var player: Player
var _mort_signalee := false
var _temps_securite := 0.0

const DUREE_SECOURS_REAPPARITION := 1.25

func enter() -> void:
	_mort_signalee = false
	_temps_securite = DUREE_SECOURS_REAPPARITION
	player.velocity.x = 0.0
	player.sante.arreter_invincibilite()
	player.visuel.animation_terminee.connect(_sur_animation_terminee)
	player.visuel.jouer("Dead", true)
	# Toutes les morts passent par ici : coup fatal, chute mortelle, kill zone.
	Audio.jouer("mort_joueur")

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func physics_update(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.vitesse * 4.0 * delta)
	_temps_securite -= delta
	if _temps_securite <= 0.0:
		# Fin d'animation non reçue : réapparition de secours.
		_signaler_mort()

func update(_delta: float) -> void:
	pass

func exit() -> void:
	player.visuel.animation_terminee.disconnect(_sur_animation_terminee)

func _sur_animation_terminee(nom: String) -> void:
	if nom == "Dead":
		_signaler_mort()


func _signaler_mort() -> void:
	if _mort_signalee:
		return
	_mort_signalee = true
	player.est_mort.emit()

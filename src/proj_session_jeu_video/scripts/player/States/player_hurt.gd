class_name PlayerHurt
extends BaseState

@export var player: Player
@export var duree := 0.35
var temps_restant := 0.0

func enter() -> void:
	temps_restant = duree
	player.sante.activer_invincibilite()
	player.visuel.jouer("Hurt")

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func physics_update(delta: float) -> void:
	temps_restant -= delta
	player.velocity.x = move_toward(player.velocity.x, 0.0, 600.0 * delta)

func update(_delta: float) -> void:
	if temps_restant > 0.0:
		return
	if not player.is_on_floor():
		Transitioned.emit(self, &"PlayerJump" if player.velocity.y < 0.0 else &"PlayerFall")
	elif not is_zero_approx(player.velocity.x):
		Transitioned.emit(self, "PlayerRun")
	else:
		Transitioned.emit(self, &"PlayerFire" if player.arsenal.temps_depuis_tir < 0.25 else &"PlayerIdle")

func exit() -> void:
	pass

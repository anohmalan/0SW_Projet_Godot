class_name PlayerFire
extends BaseState

@export var player: Player

func enter() -> void:
	player.visuel.jouer("Shoot")

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	if not player.au_sol_ou_presque():
		Transitioned.emit(self, player.etat_en_l_air())
	elif player.etat_au_sol() != &"PlayerFire":
		Transitioned.emit(self, player.etat_au_sol())
	else:
		player.visuel.jouer("Shoot")

func physics_update(delta: float) -> void:
	player.deplacer_horizontalement(delta)
	if player.essayer_de_sauter():
		Transitioned.emit(self, &"PlayerJump")

func exit() -> void:
	pass

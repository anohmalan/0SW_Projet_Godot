class_name PlayerRun
extends BaseState

@export var player: Player

func enter() -> void:
	player.visuel.jouer(player.nom_animation_mouvement("Run"))

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	if not player.au_sol_ou_presque():
		Transitioned.emit(self, player.etat_en_l_air())
	elif player.etat_au_sol() != &"PlayerRun":
		Transitioned.emit(self, player.etat_au_sol())
	else:
		player.visuel.jouer(player.nom_animation_mouvement("Run"))

func physics_update(delta: float) -> void:
	player.deplacer_horizontalement(delta)
	if player.essayer_de_sauter():
		Transitioned.emit(self, &"PlayerJump")
	elif player.veut_s_accroupir():
		Transitioned.emit(self, &"PlayerCrouch")

func exit() -> void:
	pass

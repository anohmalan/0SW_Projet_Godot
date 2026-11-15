class_name PlayerIdle
extends BaseState

@export var player: Player

func enter() -> void:
	# Premier enter() appelé par la StateMachine avant le _ready() du joueur.
	if player.is_node_ready():
		player.visuel.jouer(player.nom_animation_mouvement("Idle"))

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	if not player.au_sol_ou_presque():
		Transitioned.emit(self, player.etat_en_l_air())
	elif player.etat_au_sol() != &"PlayerIdle":
		Transitioned.emit(self, player.etat_au_sol())
	else:
		player.visuel.jouer(player.nom_animation_mouvement("Idle"))

func physics_update(delta: float) -> void:
	player.deplacer_horizontalement(delta)
	if player.essayer_de_sauter():
		Transitioned.emit(self, &"PlayerJump")
	elif player.veut_s_accroupir():
		Transitioned.emit(self, &"PlayerCrouch")

func exit() -> void:
	pass

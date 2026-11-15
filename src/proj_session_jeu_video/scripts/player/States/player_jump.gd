class_name PlayerJump
extends BaseState

@export var player: Player

func enter() -> void:
	if player.consommer_saut():
		# Vrai saut : l'animation repart du moment de l'impulsion.
		player.visuel.jouer(player.nom_animation_mouvement("Jump"), true, 400.0)
	else:
		# Montée sans saut (recul, plateforme) : on garde l'animation en cours.
		player.visuel.jouer(player.nom_animation_mouvement("Jump"))

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	if player.is_on_floor():
		Transitioned.emit(self, player.etat_au_sol())
	elif player.velocity.y >= 0.0:
		Transitioned.emit(self, &"PlayerFall")
	else:
		player.visuel.jouer(player.nom_animation_mouvement("Jump"))

func physics_update(delta: float) -> void:
	player.deplacer_horizontalement(delta)
	player.couper_saut_si_relache()

func exit() -> void:
	pass

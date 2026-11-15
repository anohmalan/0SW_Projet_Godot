class_name PlayerFall
extends BaseState

@export var player: Player

func enter() -> void:
	player.visuel.jouer(player.nom_animation_mouvement("Jump"))

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	if player.is_on_floor():
		Transitioned.emit(self, player.etat_au_sol())
	elif player.velocity.y < 0.0:
		Transitioned.emit(self, &"PlayerJump")
	else:
		player.visuel.jouer(player.nom_animation_mouvement("Jump"))

func physics_update(delta: float) -> void:
	player.deplacer_horizontalement(delta)
	# Tolérance au bord : on peut encore sauter juste après avoir quitté un rebord.
	if player.essayer_de_sauter():
		Transitioned.emit(self, &"PlayerJump")

func exit() -> void:
	pass

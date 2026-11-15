class_name PlayerCrouch
extends BaseState

## Accroupi : silhouette réduite, immobile, peut se retourner et tirer.

@export var player: Player

func enter() -> void:
	player.s_accroupir()
	player.visuel.jouer(_animation())

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func physics_update(delta: float) -> void:
	player.freiner_horizontalement(delta)
	var axe := Input.get_axis("gauche", "droite")
	if axe != 0.0:
		player.orienter(1 if axe > 0.0 else -1)
	# Sauter depuis l'accroupi : il faut d'abord pouvoir se relever.
	if player.peut_se_relever() and player.essayer_de_sauter():
		player.se_relever()
		Transitioned.emit(self, &"PlayerJump")

func update(_delta: float) -> void:
	if not player.au_sol_ou_presque():
		player.se_relever(true)
		Transitioned.emit(self, player.etat_en_l_air())
	elif Input.get_action_strength("bas") < player.seuil_accroupi and player.se_relever():
		Transitioned.emit(self, player.etat_au_sol())
	else:
		player.visuel.jouer(_animation())

func exit() -> void:
	# Pas de se_relever() ici : PlayerMelee garde la posture accroupie (Crouch_Melee).
	pass

func _animation() -> String:
	if player.vient_de_tirer():
		return "Crouch_Shoot"
	return player.nom_animation_mouvement("Crouch")

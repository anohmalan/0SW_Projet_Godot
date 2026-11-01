class_name PlayerRun
extends BaseState

@export var player: Player

func enter() -> void:
	player.visuel.jouer(player.nom_animation_mouvement("Run"))

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	if not player.is_on_floor():
		Transitioned.emit(self, "PlayerJump" if player.velocity.y < 0.0 else "PlayerFall")
	elif is_zero_approx(player.velocity.x):
		Transitioned.emit(self, "PlayerFire" if player.arsenal.temps_depuis_tir < 0.25 else "PlayerIdle")
	else:
		player.visuel.jouer(player.nom_animation_mouvement("Run"))

func physics_update(_delta: float) -> void:
	var axe := Input.get_axis("gauche", "droite")
	player.velocity.x = axe * player.vitesse
	if axe != 0.0:
		player._orienter(1 if axe > 0.0 else -1)
	if Input.is_action_just_pressed("saut") and player.is_on_floor():
		Transitioned.emit(self, "PlayerJump")

func exit() -> void:
	pass
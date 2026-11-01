class_name PlayerFall
extends BaseState

@export var player: Player

func enter() -> void:
	player.visuel.jouer(player.nom_animation_mouvement("Jump"))

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	if player.is_on_floor():
		if not is_zero_approx(player.velocity.x):
			Transitioned.emit(self, "PlayerRun")
		else:
			Transitioned.emit(self, "PlayerFire" if player.arsenal.temps_depuis_tir < 0.25 else "PlayerIdle")
	elif player.velocity.y < 0.0:
		Transitioned.emit(self, "PlayerJump")
	else:
		player.visuel.jouer(player.nom_animation_mouvement("Jump"))

func physics_update(_delta: float) -> void:
	var axe := Input.get_axis("gauche", "droite")
	player.velocity.x = axe * player.vitesse
	if axe != 0.0:
		player._orienter(1 if axe > 0.0 else -1)
	if Input.is_action_just_released("saut") and player.velocity.y < 0.0:
		player.velocity.y *= 0.5

func exit() -> void:
	print("On sort de fall")
	pass
class_name PlayerIdle
extends BaseState

@export var player: Player

func enter() -> void:
	if player.is_node_ready():
		player.visuel.jouer(player.nom_animation_mouvement("Idle"))

func handle_inputs(_input_event: InputEvent) -> void:
	if not player.is_on_floor():
		return
	if _input_event.is_action_pressed("saut"):
		Transitioned.emit(self, "PlayerJump")
	elif _input_event.is_action_pressed("tir"):
		Transitioned.emit(self, "PlayerFire")

func update(_delta: float) -> void:
	player.visuel.jouer(player.nom_animation_mouvement("Idle"))

func physics_update(_delta: float) -> void:
	var axe := Input.get_axis("gauche", "droite")
	player.velocity.x = axe * player.vitesse
	if axe != 0.0:
		Transitioned.emit(self, "PlayerRun")
	if Input.is_action_just_pressed("saut") and player.is_on_floor():
		Transitioned.emit(self, &"PlayerJump")

func exit() -> void:
	print("On sort de idle")
	pass
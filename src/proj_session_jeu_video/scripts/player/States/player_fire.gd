class_name PlayerFire
extends BaseState

@export var player: Player

func enter() -> void:
	player.visuel.jouer("Shoot")

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	if not player.is_on_floor():
		Transitioned.emit(self, &"PlayerJump" if player.velocity.y < 0.0 else &"PlayerFall")
	elif not is_zero_approx(player.velocity.x):
		Transitioned.emit(self, &"PlayerRun")
	elif player.arsenal.temps_depuis_tir >= 0.25:
		Transitioned.emit(self, &"PlayerIdle")
	else:
		player.visuel.jouer("Shoot")

func physics_update(_delta: float) -> void:
	var axe := Input.get_axis("gauche", "droite")
	player.velocity.x = axe * player.vitesse
	if axe != 0.0:
		player._orienter(1 if axe > 0.0 else -1)
	if Input.is_action_just_pressed("saut") and player.is_on_floor():
		Transitioned.emit(self, &"PlayerJump")

func exit() -> void:
	pass
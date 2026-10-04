extends Node2D

const ANIMS := ["Idle", "Idle_Aim", "Walk", "Run", "Run_Aim",
		"Jump", "Jump_Aim", "Shoot", "Hurt", "Dead"]
var _i := 0

@onready var visuel: VisuelSoldat = $Visuel

func _ready() -> void:
	visuel.position = Vector2(576, 360)
	visuel.animation_terminee.connect(func(nom): print("Terminée : ", nom))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_RIGHT:
				_i = (_i + 1) % ANIMS.size()
				visuel.jouer(ANIMS[_i])
				print(ANIMS[_i])
			KEY_LEFT:
				_i = (_i - 1 + ANIMS.size()) % ANIMS.size()
				visuel.jouer(ANIMS[_i])
				print(ANIMS[_i])
			KEY_R:
				visuel.jouer(ANIMS[_i], true)
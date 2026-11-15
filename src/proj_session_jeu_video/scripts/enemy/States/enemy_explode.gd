class_name EnemyExplode
extends BaseState

## Kamikaze arrivé au contact : il s'amorce en tremblant, puis explose.

@export var enemy: Enemy
@export var tremblement := 2.5

var _temps := 0.0
var _a_explose := false

func enter() -> void:
	_temps = 0.0
	_a_explose = false
	enemy.sprite.play(&"attack")
	enemy.flasher(Color(1.0, 0.5, 0.1, 0.8), enemy.duree_amorce)

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func physics_update(delta: float) -> void:
	_temps += delta
	enemy.freiner(delta, 600.0)
	enemy.sprite.position.x = randf_range(-tremblement, tremblement)
	if not _a_explose and _temps >= enemy.duree_amorce:
		_a_explose = true
		enemy.exploser()

func update(_delta: float) -> void:
	pass

func exit() -> void:
	enemy.sprite.position.x = 0.0

class_name EnemyExplode
extends BaseState

## Kamikaze arrivé au contact : il s'amorce en tremblant et en bipant de plus en plus vite,
## puis explose.

@export var enemy: Enemy
@export var tremblement := 2.5
## Intervalle entre deux bips au début puis à la fin de l'amorce (secondes).
@export var intervalle_bip_debut := 0.2
@export var intervalle_bip_fin := 0.05

var _temps := 0.0
var _a_explose := false
var _prochain_bip := 0.0

func enter() -> void:
	_temps = 0.0
	_a_explose = false
	_prochain_bip = 0.0
	enemy.sprite.play(&"attack")
	enemy.flasher(Color(1.0, 0.5, 0.1, 0.8), enemy.duree_amorce)

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func physics_update(delta: float) -> void:
	_temps += delta
	enemy.freiner(delta, 600.0)
	enemy.sprite.position.x = randf_range(-tremblement, tremblement)
	if _temps >= _prochain_bip and not _a_explose:
		Audio.jouer("amorce_kamikaze", enemy.global_position, -2.0, 0.0)
		var avancement := clampf(_temps / enemy.duree_amorce, 0.0, 1.0)
		_prochain_bip = _temps + lerpf(intervalle_bip_debut, intervalle_bip_fin, avancement)
	if not _a_explose and _temps >= enemy.duree_amorce:
		_a_explose = true
		enemy.exploser()

func update(_delta: float) -> void:
	pass

func exit() -> void:
	enemy.sprite.position.x = 0.0

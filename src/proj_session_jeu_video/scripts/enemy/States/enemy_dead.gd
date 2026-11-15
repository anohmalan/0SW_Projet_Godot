class_name EnemyDead
extends BaseState

@export var enemy: Enemy
@export var gravite := 600.0

func enter() -> void:
	enemy.desactiver_collisions()
	enemy.velocity.x = 0.0
	enemy.sprite.animation_finished.connect(_sur_fin_animation)
	enemy.sprite.play(&"death")

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func physics_update(delta: float) -> void:
	# Plus d'ailes : le corps chute jusqu'au décor.
	enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 300.0 * delta)
	enemy.velocity.y += gravite * delta

func update(_delta: float) -> void:
	pass

func exit() -> void:
	enemy.sprite.animation_finished.disconnect(_sur_fin_animation)

func _sur_fin_animation() -> void:
	enemy.est_mort.emit()
	enemy.queue_free()

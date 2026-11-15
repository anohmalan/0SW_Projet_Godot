class_name EnemyHurt
extends BaseState

@export var enemy: Enemy

func enter() -> void:
	enemy.sprite.animation_finished.connect(_sur_fin_animation)
	enemy.sprite.play(&"hurt")

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func physics_update(delta: float) -> void:
	enemy.freiner(delta)

func update(_delta: float) -> void:
	pass

func exit() -> void:
	enemy.sprite.animation_finished.disconnect(_sur_fin_animation)

func _sur_fin_animation() -> void:
	# Touché, il repère le joueur et riposte.
	Transitioned.emit(self, &"EnemyChase")

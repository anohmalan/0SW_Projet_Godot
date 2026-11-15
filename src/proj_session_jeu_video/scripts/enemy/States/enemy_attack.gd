class_name EnemyAttack
extends BaseState

@export var enemy: Enemy
var _a_tire := false

func enter() -> void:
	_a_tire = false
	enemy.temps_depuis_attaque = 0.0
	var player := enemy.joueur_cible()
	if player != null:
		enemy.orienter(1 if player.global_position.x >= enemy.global_position.x else -1)
	enemy.sprite.frame_changed.connect(_sur_image)
	enemy.sprite.animation_finished.connect(_sur_fin_animation)
	enemy.sprite.play(&"attack")
	# Signal pour le joueur : l'ennemi rougit juste avant que le rayon parte.
	enemy.flasher(Color(1.0, 0.2, 0.3, 0.6), 0.35)
	Audio.jouer("charge_ennemi", enemy.global_position, -4.0)

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func physics_update(delta: float) -> void:
	enemy.freiner(delta)

func update(_delta: float) -> void:
	pass

func exit() -> void:
	enemy.sprite.frame_changed.disconnect(_sur_image)
	enemy.sprite.animation_finished.disconnect(_sur_fin_animation)

func _sur_image() -> void:
	# Le rayon part sur l'image où l'œil s'illumine.
	if not _a_tire and enemy.sprite.frame == Enemy.IMAGE_TIR:
		_a_tire = true
		enemy.tirer()

func _sur_fin_animation() -> void:
	Transitioned.emit(self, &"EnemyChase")

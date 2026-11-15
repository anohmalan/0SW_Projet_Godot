class_name EnemyPatrol
extends BaseState

@export var enemy: Enemy

func enter() -> void:
	# Premier enter() appelé par la StateMachine avant le _ready() de l'ennemi :
	# sprite n'existe pas encore, mais l'autoplay "move" du Sprite couvre ce cas.
	if enemy.is_node_ready():
		enemy.sprite.play(&"move")

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func physics_update(delta: float) -> void:
	var gauche := enemy.position_depart.x - enemy.distance_patrouille
	var droite := enemy.position_depart.x + enemy.distance_patrouille
	if enemy.direction > 0 and enemy.global_position.x >= droite:
		enemy.orienter(-1)
	elif enemy.direction < 0 and enemy.global_position.x <= gauche:
		enemy.orienter(1)
	elif enemy.is_on_wall():
		var normale := signf(enemy.get_wall_normal().x)
		if normale != 0.0 and normale != enemy.direction:
			enemy.orienter(int(normale))
	# Avance dans sa direction en revenant à son altitude de départ.
	var cible := Vector2(enemy.global_position.x + enemy.direction * 32.0, enemy.position_depart.y)
	enemy.voler_vers(cible, enemy.vitesse_patrouille, delta)

func update(_delta: float) -> void:
	var player := enemy.joueur_cible()
	if player != null and enemy.distance_joueur(player) <= enemy.portee_detection:
		Transitioned.emit(self, &"EnemyChase")

func exit() -> void:
	pass

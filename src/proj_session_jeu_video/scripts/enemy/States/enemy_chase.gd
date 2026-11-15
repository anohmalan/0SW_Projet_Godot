class_name EnemyChase
extends BaseState

@export var enemy: Enemy
## Au-delà de portee_detection × ce facteur, l'ennemi abandonne la poursuite.
@export var facteur_abandon := 1.4
## Temps pendant lequel il continue de chercher un joueur caché derrière le décor.
@export var memoire := 2.5
var _temps_sans_vue := 0.0

func enter() -> void:
	_temps_sans_vue = 0.0
	enemy.sprite.play(&"move")

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func physics_update(delta: float) -> void:
	var player := enemy.joueur_cible()
	if player == null:
		enemy.freiner(delta)
		return
	var sens := 1 if player.global_position.x >= enemy.global_position.x else -1
	enemy.orienter(sens)
	# Se place en hauteur, à distance de tir, du côté où il se trouve déjà.
	var cible := enemy.point_vise(player) + Vector2(-sens * enemy.distance_ideale, -enemy.hauteur_vol)
	enemy.voler_vers(cible, enemy.vitesse_poursuite, delta)

func update(delta: float) -> void:
	var player := enemy.joueur_cible()
	if player == null:
		Transitioned.emit(self, &"EnemyPatrol")
		return
	var visible := enemy.voit_joueur(player)
	_temps_sans_vue = 0.0 if visible else _temps_sans_vue + delta
	var distance := enemy.distance_joueur(player)
	if distance > enemy.portee_detection * facteur_abandon or _temps_sans_vue > memoire:
		Transitioned.emit(self, &"EnemyPatrol")
	elif visible and distance <= enemy.portee_attaque \
			and enemy.temps_depuis_attaque >= enemy.delai_attaque:
		Transitioned.emit(self, &"EnemyAttack")

func exit() -> void:
	pass

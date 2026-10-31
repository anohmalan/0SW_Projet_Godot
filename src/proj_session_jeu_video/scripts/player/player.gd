class_name Player
extends CharacterBody2D

signal vie_changee(vie: int, vie_max: int)
signal tir_demande(position: Vector2, direction: Vector2, arme: Arme)
signal arme_changee(arme: Arme, munitions: int)
signal munitions_changees(munitions: int)
signal est_mort

@export var vitesse := 220.0
@export var vitesse_saut := 520.0
@export var gravite := 1400.0
@export var echelle_visuel := 0.25

var direction := 1

@onready var visuel: VisuelPlayer = $Visuel
@onready var state_machine: StateMachine = $StateMachine
@onready var arsenal: ArsenalPlayer = $Arsenal
@onready var sante: ViePlayer = $Vie

const DUREE_VISEE := 1.0


func _ready() -> void:
	# Le joueur pilote la machine une fois par tick, avant et apres les collisions.
	state_machine.set_physics_process(false)
	state_machine.set_process(false)
	visuel.position = Vector2(0, -170.0 * echelle_visuel)
	_orienter(1)
	sante.initialiser(self)
	arsenal.initialiser(self)


func _physics_process(delta: float) -> void:
	arsenal.temps_depuis_tir += delta
	sante.update(delta)
	if not is_on_floor():
		velocity.y += gravite * delta
	state_machine.physics_update(delta)
	if not (state_machine.current_state is PlayerHurt or state_machine.current_state is PlayerDead):
		arsenal.gerer_commandes()
	move_and_slide()
	state_machine.update(delta)


func rafraichir() -> void:
	vie_changee.emit(sante.vie, sante.vie_max)
	arsenal.rafraichir()


func recevoir_degats(quantite: int, origine_x: float = INF) -> void:
	sante.recevoir_degats(quantite, origine_x)


func ajouter_munitions(i: int, quantite: int) -> void:
	arsenal.ajouter_munitions(i, quantite)


func _orienter(d: int) -> void:
	direction = d
	visuel.scale = Vector2(echelle_visuel * d, echelle_visuel)


func nom_animation_mouvement(base: String) -> String:
	return base + "_Aim" if arsenal.temps_depuis_tir < DUREE_VISEE else base

class_name Player
extends CharacterBody2D

signal vie_changee(vie: int, vie_max: int)
signal tir_demande(position: Vector2, direction: Vector2, arme: Arme)
signal arme_changee(arme: Arme, munitions: int)
signal munitions_changees(munitions: int)
signal est_mort

@export_group("Déplacement")
@export var vitesse := 220.0
@export var acceleration_sol := 1800.0
@export var deceleration_sol := 2400.0  # aussi utilisée pour faire demi-tour
@export var acceleration_air := 1100.0

@export_group("Saut")
@export var vitesse_saut := 560.0
@export var gravite := 1400.0
@export var vitesse_chute_max := 900.0
## Après avoir quitté un rebord, le saut reste possible pendant ce délai (coyote time).
@export var tolerance_bord := 0.1
## Un appui sur saut juste avant d'atterrir est gardé en mémoire pendant ce délai.
@export var memoire_saut := 0.12
## Facteur appliqué à la vitesse de montée quand on relâche saut (saut court).
@export var coupure_saut := 0.5

@export_group("Visuel")
@export var echelle_visuel := 0.25

const DUREE_VISEE := 1.0      # durée de la pose de visée après un tir
const DUREE_POSE_TIR := 0.25  # immobile, le joueur reste en état Fire pendant ce délai

var direction := 1
var _temps_hors_sol := 0.0
var _temps_depuis_appui_saut := INF
var _vient_de_sauter := false

@onready var visuel: VisuelPlayer = $Visuel
@onready var state_machine: StateMachine = $StateMachine
@onready var arsenal: ArsenalPlayer = $Arsenal
@onready var sante: ViePlayer = $Vie
@onready var camera: CameraPlayer = $Camera2D


func _ready() -> void:
	# Le joueur pilote la machine une fois par tick, avant et apres les collisions.
	state_machine.set_physics_process(false)
	state_machine.set_process(false)
	visuel.position = Vector2(0, -170.0 * echelle_visuel)
	orienter(1)
	sante.initialiser(self)
	arsenal.initialiser(self)
	visuel.appliquer_apparence(ApparencePlayer.selection)


func _physics_process(delta: float) -> void:
	arsenal.temps_depuis_tir += delta
	sante.update(delta)
	_temps_hors_sol = 0.0 if is_on_floor() else _temps_hors_sol + delta
	if Input.is_action_just_pressed("saut"):
		_temps_depuis_appui_saut = 0.0
	else:
		_temps_depuis_appui_saut += delta
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravite * delta, vitesse_chute_max)
	state_machine.physics_update(delta)
	var doit_tirer := false
	if not (state_machine.current_state is PlayerHurt or state_machine.current_state is PlayerDead):
		doit_tirer = arsenal.gerer_commandes()
	move_and_slide()
	state_machine.update(delta)
	if doit_tirer:
		arsenal.tirer()


# --- Déplacement -------------------------------------------------------------

## Applique l'entrée gauche/droite avec inertie et oriente le joueur. Renvoie l'axe lu.
func deplacer_horizontalement(delta: float) -> float:
	var axe := Input.get_axis("gauche", "droite")
	var cible := axe * vitesse
	var acceleration := acceleration_air
	if is_on_floor():
		var demi_tour := axe != 0.0 and signf(axe) != signf(velocity.x) and velocity.x != 0.0
		acceleration = acceleration_sol if axe != 0.0 and not demi_tour else deceleration_sol
	velocity.x = move_toward(velocity.x, cible, acceleration * delta)
	if axe != 0.0:
		orienter(1 if axe > 0.0 else -1)
	return axe


func orienter(d: int) -> void:
	direction = d
	visuel.scale = Vector2(echelle_visuel * d, echelle_visuel)


## Au sol, ou à peine décollé : évite de basculer en chute pour une seule image
## (bord franchi, plateforme qui descend).
func au_sol_ou_presque() -> bool:
	return _temps_hors_sol <= tolerance_bord


# --- Saut --------------------------------------------------------------------

## Saute si un appui récent coïncide avec un sol récent. À appeler par les états qui autorisent le saut.
func essayer_de_sauter() -> bool:
	if _temps_depuis_appui_saut > memoire_saut or _temps_hors_sol > tolerance_bord:
		return false
	velocity.y = -vitesse_saut
	_temps_depuis_appui_saut = INF
	_temps_hors_sol = INF  # un seul saut par contact avec le sol
	_vient_de_sauter = true
	return true


## Relâcher saut pendant la montée raccourcit le saut.
func couper_saut_si_relache() -> void:
	if Input.is_action_just_released("saut") and velocity.y < 0.0:
		velocity.y *= coupure_saut


## Vrai une seule fois après un saut : l'état Jump relance alors son animation.
func consommer_saut() -> bool:
	var resultat := _vient_de_sauter
	_vient_de_sauter = false
	return resultat


# --- Choix des états ---------------------------------------------------------

func vient_de_tirer() -> bool:
	return arsenal.temps_depuis_tir < DUREE_POSE_TIR


func etat_au_sol() -> StringName:
	if not is_zero_approx(velocity.x):
		return &"PlayerRun"
	return &"PlayerFire" if vient_de_tirer() else &"PlayerIdle"


func etat_en_l_air() -> StringName:
	return &"PlayerJump" if velocity.y < 0.0 else &"PlayerFall"


# --- Vie ---------------------------------------------------------------------

func rafraichir() -> void:
	vie_changee.emit(sante.vie, sante.vie_max)
	arsenal.rafraichir()


func recevoir_degats(quantite: int, origine_x: float = INF) -> void:
	sante.recevoir_degats(quantite, origine_x)


func mourir() -> void:
	if state_machine.current_state is PlayerDead:
		return
	sante.vie = 0
	vie_changee.emit(sante.vie, sante.vie_max)
	state_machine.change_state("PlayerDead")


func reapparaitre(position_depart: Vector2) -> void:
	global_position = position_depart
	velocity = Vector2.ZERO
	_temps_hors_sol = 0.0
	_temps_depuis_appui_saut = INF
	_vient_de_sauter = false
	sante.initialiser(self)
	sante.arreter_invincibilite()
	orienter(1)
	camera.recentrer()
	state_machine.change_state(&"PlayerIdle")
	rafraichir()


func ajouter_munitions(i: int, quantite: int) -> void:
	arsenal.ajouter_munitions(i, quantite)


func nom_animation_mouvement(base: String) -> String:
	return base + "_Aim" if arsenal.temps_depuis_tir < DUREE_VISEE else base

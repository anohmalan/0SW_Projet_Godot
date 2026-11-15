class_name Player
extends CharacterBody2D

signal vie_changee(vie: int, vie_max: int)
signal coeurs_changes(coeurs: int, coeurs_max: int)
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

@export_group("Chute")
## En dessous de cette hauteur de chute (pixels), aucun dégât.
@export var chute_sans_degats := 350.0
## À partir de cette hauteur, la chute est mortelle ; entre les deux, les dégâts croissent.
@export var chute_mortelle := 1000.0

@export_group("Accroupi")
@export var hauteur_accroupi := 80.0
## Au-delà de cette pression sur "bas" (stick), le joueur s'accroupit : évite les accroupissements
## involontaires en courant avec le stick légèrement incliné.
@export var seuil_accroupi := 0.6

@export_group("Corps à corps")
@export var degats_melee := 25
@export var duree_melee := 0.5
## Moment du coup de couteau, en secondes après le début de l'animation.
@export var moment_impact := 0.2
@export var delai_melee := 0.15

@export_group("Visuel")
@export var echelle_visuel := 0.25

const EFFET_REAPPARITION := preload("res://scripts/player/effet_reapparition.gd")
const DUREE_VISEE := 1.0      # durée de la pose de visée après un tir
const DUREE_POSE_TIR := 0.25  # immobile, le joueur reste en état Fire pendant ce délai

var direction := 1
var _temps_hors_sol := 0.0
var _temps_depuis_appui_saut := INF
var _vient_de_sauter := false
var accroupi := false
var temps_depuis_melee := 99.0
var _hauteur_debout := 0.0
## Point le plus haut (y minimal) atteint depuis que le joueur a quitté le sol.
var _y_plus_haut := 0.0
## Vrai jusqu'au premier contact avec le sol après une apparition : la descente depuis le
## point d'apparition n'est pas une vraie chute.
var _ignorer_chute := true
## Dernier endroit où le joueur se tenait sur le décor fixe : il y réapparaît après une mort.
var derniere_position_sure := Vector2.ZERO

@onready var visuel: VisuelPlayer = $Visuel
@onready var state_machine: StateMachine = $StateMachine
@onready var arsenal: ArsenalPlayer = $Arsenal
@onready var sante: ViePlayer = $Vie
@onready var camera: CameraPlayer = $Camera2D
@onready var forme: CollisionShape2D = $CollisionShape2D
@onready var zone_melee: Area2D = $ZoneMelee


func _ready() -> void:
	# Le joueur pilote la machine une fois par tick, avant et apres les collisions.
	state_machine.set_physics_process(false)
	state_machine.set_process(false)
	# Forme propre à cette instance : on change sa hauteur quand le joueur s'accroupit.
	forme.shape = forme.shape.duplicate()
	_hauteur_debout = (forme.shape as CapsuleShape2D).height
	visuel.position = Vector2(0, -170.0 * echelle_visuel)
	orienter(1)
	derniere_position_sure = global_position
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
	temps_depuis_melee += delta
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravite * delta, vitesse_chute_max)
	var etat := state_machine.current_state
	var libre := not (etat is PlayerHurt or etat is PlayerDead or etat is PlayerMelee)
	# Le coup de couteau est possible depuis n'importe quel état « libre », au sol comme en l'air.
	if libre and Input.is_action_just_pressed("melee") and temps_depuis_melee >= delai_melee:
		state_machine.change_state(&"PlayerMelee")
		libre = false
	state_machine.physics_update(delta)
	var doit_tirer := false
	if libre:
		doit_tirer = arsenal.gerer_commandes()
	var etait_au_sol := is_on_floor()
	move_and_slide()
	_suivre_chute(etait_au_sol)
	_memoriser_position_sure()
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


## Ralentit jusqu'à l'arrêt sans lire l'entrée (accroupi, coup au sol).
func freiner_horizontalement(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, deceleration_sol * delta)


func orienter(d: int) -> void:
	direction = d
	visuel.scale = Vector2(echelle_visuel * d, echelle_visuel)
	zone_melee.scale.x = d


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


# --- Chute -------------------------------------------------------------------

## Mémorise le point le plus haut en l'air et applique les dégâts de chute à l'atterrissage.
## Retient la position du joueur quand il est debout sur le décor (TileMapLayer), et non sur
## une plateforme mobile ou en plein recul : c'est là qu'il réapparaîtra s'il meurt.
func _memoriser_position_sure() -> void:
	if not is_on_floor():
		return
	var etat := state_machine.current_state
	if etat is PlayerDead or etat is PlayerHurt:
		return
	var requete := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0.0, -4.0), global_position + Vector2(0.0, 8.0), 1, [get_rid()])
	var impact := get_world_2d().direct_space_state.intersect_ray(requete)
	if not impact.is_empty() and impact["collider"] is TileMapLayer:
		derniere_position_sure = global_position


func _suivre_chute(etait_au_sol: bool) -> void:
	if not is_on_floor():
		# Au sol, _y_plus_haut suit le joueur : en l'air, il ne garde que le point le plus haut.
		_y_plus_haut = minf(_y_plus_haut, global_position.y)
		return
	if not etait_au_sol and not _ignorer_chute:
		_atterrir(global_position.y - _y_plus_haut)
	_ignorer_chute = false
	_y_plus_haut = global_position.y


func _atterrir(hauteur: float) -> void:
	if hauteur < chute_sans_degats or state_machine.current_state is PlayerDead:
		return
	if hauteur >= chute_mortelle:
		mourir()
		return
	var proportion := (hauteur - chute_sans_degats) / (chute_mortelle - chute_sans_degats)
	var degats := maxi(1, roundi(proportion * sante.vie_max))
	sante.recevoir_degats(degats, INF, false)


# --- Accroupi ----------------------------------------------------------------

func veut_s_accroupir() -> bool:
	return is_on_floor() and Input.get_action_strength("bas") >= seuil_accroupi


func s_accroupir() -> void:
	if accroupi:
		return
	accroupi = true
	_appliquer_hauteur(hauteur_accroupi)


## Renvoie false (et reste accroupi) si un plafond empêche de se relever.
func se_relever(forcer: bool = false) -> bool:
	if not accroupi:
		return true
	if not forcer and not peut_se_relever():
		return false
	accroupi = false
	_appliquer_hauteur(_hauteur_debout)
	return true


func peut_se_relever() -> bool:
	if not accroupi:
		return true
	return not test_move(global_transform, Vector2(0.0, -(_hauteur_debout - hauteur_accroupi)))


## La capsule garde ses pieds au même endroit : seul le haut descend.
func _appliquer_hauteur(hauteur: float) -> void:
	(forme.shape as CapsuleShape2D).height = hauteur
	forme.position.y = -hauteur * 0.5


# --- Corps à corps -----------------------------------------------------------

## Inflige les dégâts du couteau à tout ce qui se trouve dans la zone de frappe.
func frapper() -> void:
	for corps in zone_melee.get_overlapping_bodies():
		if corps != self and corps.has_method("recevoir_degats"):
			corps.recevoir_degats(degats_melee, global_position.x)


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
	coeurs_changes.emit(sante.coeurs, sante.coeurs_max)
	arsenal.rafraichir()


func recevoir_degats(quantite: int, origine_x: float = INF) -> void:
	sante.recevoir_degats(quantite, origine_x)


func mourir() -> void:
	if state_machine.current_state is PlayerDead:
		return
	sante.vie = 0
	vie_changee.emit(sante.vie, sante.vie_max)
	state_machine.change_state("PlayerDead")


## Remet le joueur debout, vie pleine, à la position donnée, en gardant son orientation.
## Il est brièvement invincible : il réapparaît là où il jouait, parfois près d'ennemis.
func reapparaitre(position_depart: Vector2) -> void:
	global_position = position_depart
	velocity = Vector2.ZERO
	_temps_hors_sol = 0.0
	_temps_depuis_appui_saut = INF
	_vient_de_sauter = false
	_y_plus_haut = position_depart.y
	_ignorer_chute = true
	se_relever(true)
	sante.initialiser(self)
	camera.recentrer()
	state_machine.change_state(&"PlayerIdle")
	sante.activer_invincibilite()
	_surbrillance_reapparition()
	rafraichir()


## Le joueur s'illumine en vert néon puis retrouve ses couleurs, avec un effet de lumière
## au sol (colonne + anneau) pour bien repérer où il revient.
func _surbrillance_reapparition() -> void:
	visuel.flasher(EFFET_REAPPARITION.COULEUR.lightened(0.3), 0.8)
	var effet: Node2D = EFFET_REAPPARITION.new()
	effet.position = position
	get_parent().add_child(effet)


func ajouter_munitions(i: int, quantite: int) -> void:
	arsenal.ajouter_munitions(i, quantite)


func nom_animation_mouvement(base: String) -> String:
	return base + "_Aim" if arsenal.temps_depuis_tir < DUREE_VISEE else base

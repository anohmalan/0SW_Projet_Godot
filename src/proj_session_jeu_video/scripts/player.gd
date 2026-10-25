class_name Joueur
extends CharacterBody2D

signal vie_changee(vie: int, vie_max: int)
signal tir_demande(position: Vector2, direction: Vector2, arme: Arme)
signal arme_changee(arme: Arme, munitions: int)
signal munitions_changees(munitions: int)
signal est_mort

enum Etat { NORMAL, DEGATS, MORT }

@export var vitesse := 220.0
@export var vitesse_saut := 520.0
@export var gravite := 1400.0
@export var vie_max := 100
@export var echelle_visuel := 0.25

const PIEDS := 170.0                 # origine du squelette -> pieds (pixels non réduits)
const DUREE_VISEE := 1.0             # temps passé en pose « Aim » après un tir
const DUREE_DEGATS := 0.35
const DUREE_INVINCIBLE := 1.2

var vie := 100
var direction := 1                   # 1 = droite, -1 = gauche
var etat := Etat.NORMAL
var armes: Array[Arme] = []
var munitions: Array[int] = []       # une valeur par arme (-1 = illimitées)
var index_arme := 0

var _temps_depuis_tir := 99.0
var _temps_degats := 0.0
var _invincible := 0.0
var _a_saute := false
var _famille_precedente := ""

@onready var visuel: VisuelSoldat = $Visuel


func _ready() -> void:
	vie = vie_max
	visuel.position = Vector2(0, -PIEDS * echelle_visuel)
	_orienter(1)
	visuel.animation_terminee.connect(_sur_animation_terminee)
	armes = Arme.catalogue()
	for a in armes:
		munitions.append(a.munitions_max)
	_equiper(0)


# À appeler par le niveau après avoir connecté les signaux (HUD, etc.).
func rafraichir() -> void:
	vie_changee.emit(vie, vie_max)
	arme_changee.emit(armes[index_arme], munitions[index_arme])


func _physics_process(delta: float) -> void:
	_temps_depuis_tir += delta
	_gerer_invincibilite(delta)

	if not is_on_floor():
		velocity.y += gravite * delta

	match etat:
		Etat.MORT:
			velocity.x = move_toward(velocity.x, 0.0, vitesse * 4.0 * delta)
		Etat.DEGATS:
			_temps_degats -= delta
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _temps_degats <= 0.0:
				etat = Etat.NORMAL
		Etat.NORMAL:
			_gerer_commandes()

	move_and_slide()
	_choisir_animation()


func _gerer_commandes() -> void:
	var axe := Input.get_axis("gauche", "droite")
	velocity.x = axe * vitesse
	if axe != 0.0:
		_orienter(1 if axe > 0.0 else -1)

	if Input.is_action_just_pressed("saut") and is_on_floor():
		velocity.y = -vitesse_saut
		_a_saute = true
	if Input.is_action_just_released("saut") and velocity.y < 0.0:
		velocity.y *= 0.5

	if Input.is_action_just_pressed("arme_suivante"):
		_arme_suivante()

	if Input.is_action_pressed("tir") and _temps_depuis_tir >= armes[index_arme].cadence:
		_tirer()


# ---------- Armes ----------

func _equiper(i: int) -> void:
	index_arme = i
	visuel.definir_carte("Gun", armes[i].carte)
	arme_changee.emit(armes[i], munitions[i])


func _arme_suivante() -> void:
	# On saute les armes sans munitions.
	for pas in range(1, armes.size()):
		var i := (index_arme + pas) % armes.size()
		if munitions[i] != 0:
			_equiper(i)
			return


func ajouter_munitions(i: int, quantite: int) -> void:
	if armes[i].munitions_max < 0:
		return
	munitions[i] = mini(munitions[i] + quantite, armes[i].munitions_max)
	if i == index_arme:
		munitions_changees.emit(munitions[i])


func _tirer() -> void:
	var arme := armes[index_arme]
	_temps_depuis_tir = 0.0
	var bouche := visuel.position_bouche(arme.bouche_y)
	for i in arme.projectiles:
		var ecart := deg_to_rad(randf_range(-arme.dispersion, arme.dispersion))
		tir_demande.emit(bouche, Vector2(direction, 0.0).rotated(ecart), arme)

	if munitions[index_arme] > 0:
		munitions[index_arme] -= 1
		munitions_changees.emit(munitions[index_arme])
		if munitions[index_arme] == 0:
			_arme_suivante()   # plus de munitions : on change d'arme


# ---------- Dégâts et mort ----------

func recevoir_degats(quantite: int, origine_x: float = INF) -> void:
	if etat == Etat.MORT or _invincible > 0.0:
		return
	vie = maxi(vie - quantite, 0)
	vie_changee.emit(vie, vie_max)
	if vie == 0:
		_mourir()
		return
	etat = Etat.DEGATS
	_temps_degats = DUREE_DEGATS
	_invincible = DUREE_INVINCIBLE
	var sens := float(-direction)
	if origine_x != INF:
		sens = 1.0 if global_position.x >= origine_x else -1.0
	velocity = Vector2(sens * 200.0, -220.0)


func _mourir() -> void:
	etat = Etat.MORT
	velocity.x = 0.0
	visuel.modulate.a = 1.0
	visuel.jouer("Dead", true)


func _sur_animation_terminee(nom: String) -> void:
	if nom == "Dead":
		est_mort.emit()


# ---------- Apparence ----------

func _orienter(d: int) -> void:
	direction = d
	visuel.scale = Vector2(echelle_visuel * d, echelle_visuel)


func _gerer_invincibilite(delta: float) -> void:
	if _invincible > 0.0:
		_invincible -= delta
		visuel.modulate.a = 0.35 if int(_invincible * 12.0) % 2 == 0 else 1.0
		if _invincible <= 0.0:
			visuel.modulate.a = 1.0


func _choisir_animation() -> void:
	if etat == Etat.MORT:
		return
	if etat == Etat.DEGATS:
		visuel.jouer("Hurt")
		_famille_precedente = "Degats"
		return

	if is_on_floor():
		_a_saute = false

	var famille := "Idle"
	if not is_on_floor():
		famille = "Jump"
	elif absf(velocity.x) > 10.0:
		famille = "Run"
	elif _temps_depuis_tir < 0.25:
		famille = "Tir"

	var suffixe := "_Aim" if _temps_depuis_tir < DUREE_VISEE else ""
	var nom := "Shoot" if famille == "Tir" else famille + suffixe

	visuel.vitesse = 2.0 if famille == "Jump" else 1.0

	if famille != _famille_precedente:
		var depart := 400.0 if (famille == "Jump" and not _a_saute) else 0.0
		visuel.jouer(nom, true, depart)
		_famille_precedente = famille
	else:
		visuel.changer_variante(nom)
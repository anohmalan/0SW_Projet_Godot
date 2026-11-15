class_name Enemy
extends CharacterBody2D

signal tir_demande(position: Vector2, direction: Vector2, arme: Arme)
signal est_mort

@export_group("Déplacement")
@export var vitesse_patrouille := 70.0
@export var vitesse_poursuite := 130.0
@export var distance_patrouille := 140.0 # de part et d'autre du point de départ
@export var amplitude_flottement := 5.0

@export_group("Combat")
@export var vie_max := 40
@export var portee_detection := 380.0
@export var portee_attaque := 300.0
@export var distance_ideale := 220.0 # distance horizontale gardée avec le joueur
@export var hauteur_vol := 90.0      # altitude visée au-dessus du joueur
@export var delai_attaque := 1.6
@export var degats_contact := 10

@export_group("Butin")
@export var scene_butin: PackedScene = preload("res://scenes/butin.tscn")
@export_range(0.0, 1.0) var chance_butin := 0.6

const SHADER_FLASH := preload("res://shaders/flash_touche.gdshader")
const ACCELERATION := 400.0
const MASQUE_DECOR := 1 # couche "monde" : ce qui bloque la vue
const HAUTEUR_CENTRE_JOUEUR := 58.0
const DECALAGE_OEIL := Vector2(14.0, -17.0) # sortie du rayon, sprite tourné vers la droite
const IMAGE_TIR := 2                         # image de l'animation "attack" où l'œil tire

var vie := 40
var direction := 1
var position_depart := Vector2.ZERO
var temps_depuis_attaque := 99.0
var arme: Arme
var _temps := 0.0
var _materiau_flash := ShaderMaterial.new()
var _tween_flash: Tween

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var zone_contact: Area2D = $ZoneContact
@onready var barre_vie: BarreVieEnnemi = $BarreVie
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	# Comme le joueur : la machine est pilotée une fois par tick, autour de move_and_slide.
	state_machine.set_physics_process(false)
	state_machine.set_process(false)
	vie = vie_max
	position_depart = global_position
	arme = _creer_arme()
	_materiau_flash.shader = SHADER_FLASH
	sprite.material = _materiau_flash
	orienter(direction)


func _physics_process(delta: float) -> void:
	_temps += delta
	temps_depuis_attaque += delta
	sprite.position.y = sin(_temps * 3.0) * amplitude_flottement
	state_machine.physics_update(delta)
	move_and_slide()
	state_machine.update(delta)
	_infliger_degats_contact()


func recevoir_degats(quantite: int, origine_x: float = INF) -> void:
	if vie <= 0:
		return
	vie = maxi(vie - quantite, 0)
	flasher()
	barre_vie.afficher(vie, vie_max)
	if vie == 0:
		state_machine.change_state(&"EnemyDead")
		return
	var sens := float(-direction)
	if origine_x != INF:
		sens = 1.0 if global_position.x >= origine_x else -1.0
	velocity = Vector2(sens * 120.0, -40.0)
	state_machine.change_state(&"EnemyHurt")


func orienter(d: int) -> void:
	direction = d
	sprite.flip_h = d < 0


func joueur_cible() -> Player:
	var player := get_tree().get_first_node_in_group("joueur") as Player
	if player == null or player.state_machine.current_state is PlayerDead:
		return null
	return player


func point_vise(player: Player) -> Vector2:
	return player.global_position + Vector2(0.0, -HAUTEUR_CENTRE_JOUEUR * player.global_scale.y)


func distance_joueur(player: Player) -> float:
	return global_position.distance_to(point_vise(player))


## Vrai si aucun élément du décor ne se trouve entre l'œil et le joueur.
func voit_joueur(player: Player) -> bool:
	var requete := PhysicsRayQueryParameters2D.create(
		global_position + sprite.position, point_vise(player), MASQUE_DECOR, [get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(requete).is_empty()


## Le joueur est-il assez proche ET visible ?
func detecte_joueur(player: Player, portee: float) -> bool:
	return player != null and distance_joueur(player) <= portee and voit_joueur(player)


func flasher(couleur: Color = Color.WHITE, duree: float = 0.15) -> void:
	if _tween_flash:
		_tween_flash.kill()
	_materiau_flash.set_shader_parameter("couleur_flash", couleur)
	_materiau_flash.set_shader_parameter("intensite", 1.0)
	_tween_flash = create_tween()
	_tween_flash.tween_property(_materiau_flash, "shader_parameter/intensite", 0.0, duree) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Vol amorti vers un point : ralentit en approchant pour ne pas osciller.
func voler_vers(cible: Vector2, vitesse_max: float, delta: float) -> void:
	var ecart := cible - global_position
	var voulue := ecart.normalized() * minf(vitesse_max, ecart.length() * 3.0)
	velocity = velocity.move_toward(voulue, ACCELERATION * delta)


func freiner(delta: float, force: float = 300.0) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, force * delta)


func tirer() -> void:
	var origine := global_position + sprite.position \
		+ Vector2(DECALAGE_OEIL.x * direction, DECALAGE_OEIL.y)
	var dir := Vector2(direction, 0.0)
	var player := joueur_cible()
	if player != null:
		dir = (point_vise(player) - origine).normalized()
	tir_demande.emit(origine, dir, arme)


## Laisse peut-être un butin à sa place, dans le même parent que l'ennemi.
func lacher_butin() -> void:
	if scene_butin == null or randf() > chance_butin:
		return
	var butin: Butin = scene_butin.instantiate()
	butin.type = Butin.type_au_hasard()
	butin.position = position
	get_parent().add_child(butin)


## Le corps ne gêne plus les balles ni le joueur, mais tombe encore sur le décor.
func desactiver_collisions() -> void:
	collision_layer = 0
	zone_contact.set_deferred("monitoring", false)


func _infliger_degats_contact() -> void:
	if vie <= 0:
		return
	for corps in zone_contact.get_overlapping_bodies():
		if corps is Player:
			# L'invincibilité du joueur évite les dégâts à chaque image.
			corps.recevoir_degats(degats_contact, global_position.x)


static func _creer_arme() -> Arme:
	var a := Arme.new()
	a.nom = "Rayon d'œil"
	a.degats = 12
	a.portee = 600.0
	a.vitesse_balle = 420.0
	a.couleur = Color(1.0, 0.25, 0.35)
	return a

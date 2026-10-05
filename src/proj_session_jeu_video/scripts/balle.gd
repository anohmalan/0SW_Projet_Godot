class_name Balle
extends Area2D

var actif := false

var _direction := Vector2.RIGHT
var _vitesse := 0.0
var _portee := 0.0
var _degats := 0
var _origine := Vector2.ZERO
var _couleur := Color.YELLOW


func _ready() -> void:
	body_entered.connect(_sur_contact)
	desactiver()


func activer(pos: Vector2, dir: Vector2, arme: Arme, du_joueur: bool) -> void:
	global_position = pos
	_origine = pos
	_direction = dir.normalized()
	rotation = _direction.angle()
	_vitesse = arme.vitesse_balle
	_portee = arme.portee
	_degats = arme.degats
	_couleur = arme.couleur
	# Couches : 4 = tirs du joueur, 5 = tirs des ennemis.
	# Masque : le monde (1) et la cible (3 = ennemis, ou 2 = joueur).
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(4 if du_joueur else 5, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(3 if du_joueur else 2, true)
	actif = true
	visible = true
	set_deferred("monitoring", true)
	set_physics_process(true)
	queue_redraw()


func desactiver() -> void:
	actif = false
	visible = false
	set_deferred("monitoring", false)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	global_position += _direction * _vitesse * delta
	if not Geometrie.dans_portee(_origine, global_position, _portee):
		desactiver()


func _sur_contact(corps: Node2D) -> void:
	if not actif:
		return
	if corps.has_method("recevoir_degats"):
		corps.recevoir_degats(_degats, _origine.x)
	desactiver()


func _draw() -> void:
	draw_line(Vector2(-14, 0), Vector2(2, 0), _couleur, 3.0)
	draw_circle(Vector2(2, 0), 2.5, Color.WHITE)
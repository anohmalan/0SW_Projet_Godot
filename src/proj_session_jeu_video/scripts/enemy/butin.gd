class_name Butin
extends CharacterBody2D

## Objet lâché par un ennemi : soin ou munitions. Tombe au sol, puis disparaît s'il n'est pas ramassé.

enum Type { SOIN, MUNITIONS_POMPE, MUNITIONS_SNIPER }

const QUANTITES := { Type.SOIN: 20, Type.MUNITIONS_POMPE: 6, Type.MUNITIONS_SNIPER: 3 }
const INDEX_ARME := { Type.MUNITIONS_POMPE: 1, Type.MUNITIONS_SNIPER: 2 } # voir Arme.catalogue()
const POIDS := { Type.SOIN: 4, Type.MUNITIONS_POMPE: 3, Type.MUNITIONS_SNIPER: 2 }
const COULEURS := {
	Type.SOIN: Color(0.2, 1.0, 0.5),
	Type.MUNITIONS_POMPE: Color(1.0, 0.55, 0.2),
	Type.MUNITIONS_SNIPER: Color(0.6, 0.9, 1.0),
}

@export var type := Type.SOIN
@export var gravite := 900.0
@export var duree_vie := 12.0
@export var duree_clignotement := 3.0

var _temps := 0.0

@onready var zone_ramassage: Area2D = $ZoneRamassage


static func type_au_hasard() -> Type:
	var total := 0
	for t in POIDS:
		total += POIDS[t]
	var tirage := randi_range(1, total)
	for t in POIDS:
		tirage -= POIDS[t]
		if tirage <= 0:
			return t
	return Type.SOIN


func _ready() -> void:
	add_to_group(&"butins") # repéré par la mini-carte
	# Petit saut à l'apparition pour attirer l'œil.
	velocity = Vector2(randf_range(-60.0, 60.0), -220.0)


func _physics_process(delta: float) -> void:
	_temps += delta
	velocity.y += gravite * delta
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	move_and_slide()

	for corps in zone_ramassage.get_overlapping_bodies():
		if corps is Player and _appliquer(corps):
			queue_free()
			return

	var restant := duree_vie - _temps
	if restant <= 0.0:
		queue_free()
		return
	visible = restant > duree_clignotement or int(restant * 8.0) % 2 == 0
	queue_redraw()


## Renvoie false si le joueur n'en a pas besoin : le butin reste alors au sol.
func _appliquer(player: Player) -> bool:
	if player.state_machine.current_state is PlayerDead:
		return false
	if type == Type.SOIN:
		var soigne := player.sante.soigner(QUANTITES[type])
		if soigne:
			Audio.jouer("soin")
		return soigne
	var i: int = INDEX_ARME[type]
	if player.arsenal.munitions[i] >= player.arsenal.armes[i].munitions_max:
		return false
	player.ajouter_munitions(i, QUANTITES[type])
	Audio.jouer("munitions")
	return true


func _draw() -> void:
	var centre := Vector2(0.0, -9.0 + sin(_temps * 4.0) * 2.0)
	var couleur: Color = COULEURS[type]
	var halo := couleur
	halo.a = 0.25
	draw_circle(centre, 11.0, halo)
	if type == Type.SOIN:
		draw_rect(Rect2(centre - Vector2(7, 7), Vector2(14, 14)), Color(0.05, 0.15, 0.1))
		draw_rect(Rect2(centre - Vector2(2, 5), Vector2(4, 10)), couleur)
		draw_rect(Rect2(centre - Vector2(5, 2), Vector2(10, 4)), couleur)
	else:
		# Boîte de munitions : caisse sombre et trois cartouches.
		draw_rect(Rect2(centre - Vector2(8, 5), Vector2(16, 10)), Color(0.12, 0.12, 0.1))
		for k in 3:
			draw_rect(Rect2(centre + Vector2(-6 + k * 5, -4), Vector2(3, 8)), couleur)

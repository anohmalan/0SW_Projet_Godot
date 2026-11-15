class_name CameraPlayer
extends Camera2D

## Caméra qui regarde devant le joueur. Elle ne change de côté que lorsque le joueur
## avance franchement dans l'autre sens, pour ne pas basculer à chaque petit demi-tour.

@export var decalage_avant := 431.0
@export var hauteur := -78.0
## Plus la valeur est haute, plus la caméra glisse vite vers son nouveau côté.
@export var vitesse_bascule := 1.2
## Vitesse maximale du glissement, en pixels par seconde, pour une bascule toujours douce.
@export var vitesse_max_bascule := 350.0
## Temps pendant lequel le joueur doit avancer dans l'autre sens avant que la caméra bascule.
@export var delai_bascule := 0.4
## En dessous de cette vitesse, le joueur est considéré comme immobile : pas de bascule.
@export var vitesse_min_bascule := 60.0
## Espace montré au-dessus du haut du niveau.
@export var marge_haut := 150.0

var _cote := 1
var _temps_autre_cote := 0.0

@onready var _player := get_parent() as Player


func _ready() -> void:
	recentrer()


func _process(delta: float) -> void:
	_mettre_a_jour_cote(delta)
	var cible_x := decalage_avant * _cote
	# Glissement amorti (ralentit à l'arrivée), plafonné pour ne jamais filer d'un coup.
	var x_amorti := lerpf(position.x, cible_x, 1.0 - exp(-vitesse_bascule * delta))
	position.x = move_toward(position.x, x_amorti, vitesse_max_bascule * delta)
	position.y = hauteur


## Place la caméra du côté où regarde le joueur, sans transition (départ, réapparition).
func recentrer() -> void:
	_cote = _player.direction if _player != null else 1
	_temps_autre_cote = 0.0
	position = Vector2(decalage_avant * _cote, hauteur)
	reset_smoothing()


## Empêche la caméra de montrer ce qui se trouve hors du niveau. Une marge est laissée
## au-dessus, pour ne pas couper ce qui dépasse des tuiles les plus hautes.
func limiter(zone: Rect2) -> void:
	limit_left = floori(zone.position.x)
	limit_top = floori(zone.position.y - marge_haut)
	limit_right = ceili(zone.end.x)
	limit_bottom = ceili(zone.end.y)


func _mettre_a_jour_cote(delta: float) -> void:
	if _player == null:
		return
	var vitesse := _player.velocity.x
	var avance_de_l_autre_cote := signf(vitesse) == -_cote and absf(vitesse) >= vitesse_min_bascule
	if not avance_de_l_autre_cote:
		_temps_autre_cote = 0.0
		return
	_temps_autre_cote += delta
	if _temps_autre_cote >= delai_bascule:
		_cote = -_cote
		_temps_autre_cote = 0.0

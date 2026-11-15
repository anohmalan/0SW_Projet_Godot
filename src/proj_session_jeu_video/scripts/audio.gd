extends Node

## Gestionnaire audio du jeu (autoload « Audio »).
## - Effets : Audio.jouer("saut") ou, placé dans le monde, Audio.jouer("explosion", position).
##   Les fichiers sont lus dans assets/audio/effets/<nom>.wav.
## - Musique : Audio.musique("niveau_1") lit assets/audio/musique/<nom>.wav en boucle, avec
##   un fondu enchaîné ; relancer la même piste ne la redémarre pas.
## Tourne pendant la pause (process_mode = Always) pour les sons des menus.

const DOSSIER_EFFETS := "res://assets/audio/effets/"
const DOSSIER_MUSIQUE := "res://assets/audio/musique/"
const BUS_EFFETS := &"Effets"
const BUS_MUSIQUE := &"Musique"
const TAILLE_POOL := 12
const TAILLE_POOL_2D := 12
const DUREE_FONDU := 0.8
const ATTENUATION_PAUSE_DB := -10.0

## Variation aléatoire de hauteur par défaut, pour que les sons répétés ne soient pas identiques.
@export var variation_hauteur := 0.06

var _effets := {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_2d: Array[AudioStreamPlayer2D] = []
var _suivant := 0
var _suivant_2d := 0

var _lecteur_musique: AudioStreamPlayer
var _piste := ""
var _tween_musique: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_charger_effets()
	for i in TAILLE_POOL:
		var lecteur := AudioStreamPlayer.new()
		lecteur.bus = BUS_EFFETS
		add_child(lecteur)
		_pool.append(lecteur)
	for i in TAILLE_POOL_2D:
		var lecteur := AudioStreamPlayer2D.new()
		lecteur.bus = BUS_EFFETS
		lecteur.max_distance = 1400.0
		lecteur.attenuation = 1.5
		add_child(lecteur)
		_pool_2d.append(lecteur)
	_lecteur_musique = AudioStreamPlayer.new()
	_lecteur_musique.bus = BUS_MUSIQUE
	_lecteur_musique.finished.connect(_boucler_musique)
	add_child(_lecteur_musique)


# --- Effets ------------------------------------------------------------------

## Joue un effet. Avec une position, il est placé dans le monde (atténué selon la distance).
func jouer(nom: String, position: Vector2 = Vector2.INF, volume_db: float = 0.0,
		variation: float = -1.0) -> void:
	var flux: AudioStream = _effets.get(nom)
	if flux == null:
		push_warning("Effet sonore inconnu : " + nom)
		return
	var ecart := variation_hauteur if variation < 0.0 else variation
	var hauteur := randf_range(1.0 - ecart, 1.0 + ecart)
	if position == Vector2.INF:
		var lecteur := _pool[_suivant]
		_suivant = (_suivant + 1) % _pool.size()
		lecteur.stream = flux
		lecteur.volume_db = volume_db
		lecteur.pitch_scale = hauteur
		lecteur.play()
	else:
		var lecteur_2d := _pool_2d[_suivant_2d]
		_suivant_2d = (_suivant_2d + 1) % _pool_2d.size()
		lecteur_2d.stream = flux
		lecteur_2d.volume_db = volume_db
		lecteur_2d.pitch_scale = hauteur
		lecteur_2d.global_position = position
		lecteur_2d.play()


## Joue au hasard une des variantes « nom_1 » … « nom_N » (ex. bruits de pas).
func jouer_variante(nom: String, nombre: int, position: Vector2 = Vector2.INF, volume_db: float = 0.0) -> void:
	jouer("%s_%d" % [nom, randi_range(1, nombre)], position, volume_db)


## Branche les sons de menu sur un bouton : survol/focus et validation.
func brancher_bouton(bouton: BaseButton) -> void:
	bouton.focus_entered.connect(jouer.bind("menu_navigation", Vector2.INF, -6.0, 0.0))
	bouton.pressed.connect(jouer.bind("menu_validation", Vector2.INF, -3.0, 0.0))


func _charger_effets() -> void:
	var dossier := DirAccess.open(DOSSIER_EFFETS)
	if dossier == null:
		push_warning("Dossier des effets introuvable : " + DOSSIER_EFFETS)
		return
	for fichier in dossier.get_files():
		# Dans un jeu exporté, les fichiers apparaissent avec le suffixe .import ou .remap.
		var nom_fichier := fichier.trim_suffix(".import").trim_suffix(".remap")
		if nom_fichier.get_extension() != "wav" or _effets.has(nom_fichier.get_basename()):
			continue
		var flux := load(DOSSIER_EFFETS + nom_fichier) as AudioStream
		if flux != null:
			_effets[nom_fichier.get_basename()] = flux


# --- Musique -----------------------------------------------------------------

## Lance une piste en boucle (fondu enchaîné). Chaîne vide : arrête la musique.
func musique(nom: String) -> void:
	if nom == _piste and _lecteur_musique.playing:
		return
	_piste = nom
	if _tween_musique:
		_tween_musique.kill()
	_tween_musique = create_tween()
	if _lecteur_musique.playing:
		_tween_musique.tween_property(_lecteur_musique, "volume_db", -40.0, DUREE_FONDU * 0.5)
	_tween_musique.tween_callback(_demarrer_piste)


func arreter_musique() -> void:
	musique("")


## Baisse la musique pendant la pause (ou un menu), puis la remet à son niveau.
func attenuer_musique(actif: bool) -> void:
	if _tween_musique and _tween_musique.is_running():
		return
	_lecteur_musique.volume_db = ATTENUATION_PAUSE_DB if actif else 0.0


func _demarrer_piste() -> void:
	_lecteur_musique.stop()
	if _piste.is_empty():
		return
	var chemin := DOSSIER_MUSIQUE + _piste + ".wav"
	var flux := load(chemin) as AudioStream if ResourceLoader.exists(chemin) else null
	if flux == null:
		push_warning("Musique introuvable : " + chemin)
		return
	# Boucle sans blanc : réglée dans l'import (loop_mode), forcée ici si une piste ne l'a pas.
	var wav := flux as AudioStreamWAV
	if wav != null and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	_lecteur_musique.stream = flux
	_lecteur_musique.volume_db = -40.0
	_lecteur_musique.play()
	create_tween().tween_property(_lecteur_musique, "volume_db", 0.0, DUREE_FONDU)


func _boucler_musique() -> void:
	if not _piste.is_empty():
		_lecteur_musique.play()

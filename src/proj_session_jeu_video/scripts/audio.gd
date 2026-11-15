extends Node

## Gestionnaire audio du jeu (autoload « Audio »).
## - Effets : Audio.jouer("saut") ou, placé dans le monde, Audio.jouer("explosion", position).
##   Les fichiers sont lus dans assets/audio/effets/<nom>.wav.
## - Musique : Audio.musique("niveau_1") lit assets/audio/musique/<nom>.wav en boucle, avec
##   un fondu enchaîné ; relancer la même piste ne la redémarre pas.
## - Ambiance : Audio.ambiance("jungle_insectes") lit assets/audio/ambiance/<nom>.wav en boucle,
##   sous la musique et sur le bus Effets.
## Tourne pendant la pause (process_mode = Always) pour les sons des menus.

const DOSSIER_EFFETS := "res://assets/audio/effets/"
const DOSSIER_MUSIQUE := "res://assets/audio/musique/"
const DOSSIER_AMBIANCE := "res://assets/audio/ambiance/"
const BUS_EFFETS := &"Effets"
const BUS_MUSIQUE := &"Musique"
const TAILLE_POOL := 12
const TAILLE_POOL_2D := 12
const DUREE_FONDU := 0.8
const ATTENUATION_PAUSE_DB := -10.0
## Niveau de l'ambiance par rapport aux effets : un fond discret.
const VOLUME_AMBIANCE_DB := -14.0

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

var _lecteur_ambiance: AudioStreamPlayer
var _ambiance := ""
var _tween_ambiance: Tween
var _attenue := false


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
	_lecteur_ambiance = AudioStreamPlayer.new()
	_lecteur_ambiance.bus = BUS_EFFETS
	add_child(_lecteur_ambiance)


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
	_attenue = actif
	if _lecteur_ambiance.playing:
		_lecteur_ambiance.volume_db = _volume_ambiance()
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
	_forcer_boucle(flux)
	_lecteur_musique.stream = flux
	_lecteur_musique.volume_db = -40.0
	_lecteur_musique.play()
	create_tween().tween_property(_lecteur_musique, "volume_db", 0.0, DUREE_FONDU)


func _boucler_musique() -> void:
	if not _piste.is_empty():
		_lecteur_musique.play()


# --- Ambiance ----------------------------------------------------------------

## Lance une ambiance en boucle (fondu d'entrée). Chaîne vide : l'arrête en fondu.
func ambiance(nom: String) -> void:
	if nom == _ambiance and _lecteur_ambiance.playing:
		return
	_ambiance = nom
	# Un fondu en cours (ex. arrêt par le niveau qu'on recharge) ne doit pas couper la nouvelle piste.
	if _tween_ambiance:
		_tween_ambiance.kill()
	_tween_ambiance = create_tween()
	if nom.is_empty():
		_tween_ambiance.tween_property(_lecteur_ambiance, "volume_db", -40.0, DUREE_FONDU)
		_tween_ambiance.tween_callback(_lecteur_ambiance.stop)
		return
	var chemin := DOSSIER_AMBIANCE + nom + ".wav"
	var flux := load(chemin) as AudioStream if ResourceLoader.exists(chemin) else null
	if flux == null:
		push_warning("Ambiance introuvable : " + chemin)
		return
	_forcer_boucle(flux)
	_lecteur_ambiance.stream = flux
	_lecteur_ambiance.volume_db = -40.0
	_lecteur_ambiance.play()
	_tween_ambiance.tween_property(_lecteur_ambiance, "volume_db", _volume_ambiance(), DUREE_FONDU * 2.0)


func arreter_ambiance() -> void:
	ambiance("")


func _volume_ambiance() -> float:
	return VOLUME_AMBIANCE_DB + (ATTENUATION_PAUSE_DB if _attenue else 0.0)


## Boucle sans blanc : réglée dans l'import (loop_mode) ; forcée ici si un .wav ne l'a pas.
static func _forcer_boucle(flux: AudioStream) -> void:
	var wav := flux as AudioStreamWAV
	if wav != null and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)


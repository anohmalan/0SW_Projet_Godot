class_name VisuelPlayerImportedAdapter
extends RefCounted

signal animation_terminee(nom: String)

var last_error := ""

var _prefixe_lib_anim := ""
var _loader: SpriterLoader
var _entite_importee_joueur: Node2D = null
var _animation_player: AnimationPlayer = null
var _point_bouche_noeud: Marker2D = null
var _sprite_arme: Sprite2D = null
var _bouche_y := 0.3
var _sprites_importes: Array[Sprite2D] = []
var _infos_par_chemin := {}
var _textures_cache := {}

func initialiser(
		prefixe_lib_anim: String,
		loader: SpriterLoader,
		entite_joueur: Node2D,
		animation_player: AnimationPlayer,
		sprite_arme: Sprite2D,
		point_bouche: Marker2D) -> bool:
	last_error = ""
	if entite_joueur == null or animation_player == null or sprite_arme == null or point_bouche == null:
		return _echouer("Configure les références entite_joueur, animation_player, sprite_arme et point_bouche sur Visuel.")
	if point_bouche.get_parent() != sprite_arme:
		return _echouer("Le Marker2D point_bouche doit être enfant du sprite_arme dans la scène.")
	_prefixe_lib_anim = prefixe_lib_anim
	_loader = loader
	_entite_importee_joueur = entite_joueur
	_animation_player = animation_player
	_sprite_arme = sprite_arme
	_point_bouche_noeud = point_bouche
	_indexer_infos_fichiers()
	_sprites_importes.assign(entite_joueur.find_children("*", "Sprite2D", true, false))
	_animation_player.animation_finished.connect(_sur_animation_finie)
	_actualiser_point_bouche()
	return true

func jouer(nom: String, relancer: bool, depart: float, vitesse: float, nom_animation_actuel: String) -> String:
	if _animation_player == null:
		return ""

	var nom_anim := _normaliser_nom_animation(nom)
	if nom_anim.is_empty():
		push_error("Animation importée inconnue : " + nom)
		return ""

	if nom_anim == nom_animation_actuel and not relancer:
		_animation_player.speed_scale = vitesse
		return nom_animation_actuel

	_animation_player.speed_scale = vitesse
	_animation_player.play(nom_anim)
	if depart > 0.0:
		_animation_player.seek(depart / 1000.0, true)
	else:
		# Appliquer la pose immédiatement, avant un éventuel tir dans le même tick.
		_animation_player.advance(0.0)
	return nom_anim

func position_animation_ms() -> float:
	if _animation_player == null:
		return 0.0
	return _animation_player.current_animation_position * 1000.0

func position_bouche(bouche_y: float) -> Vector2:
	_bouche_y = bouche_y
	if not _actualiser_point_bouche():
		push_error("Impossible de positionner la bouche : sprite_arme ou point_bouche invalide, ou arme masquée.")
		return Vector2.ZERO
	return _point_bouche_noeud.global_position

func _actualiser_point_bouche() -> bool:
	if _point_bouche_noeud == null or _sprite_arme == null:
		return false
	if _sprite_arme.texture == null or not _sprite_arme.is_visible_in_tree() or is_zero_approx(_sprite_arme.modulate.a):
		return false
	var rect := _sprite_arme.get_rect()
	_point_bouche_noeud.position = rect.position + Vector2(rect.size.x, rect.size.y * _bouche_y)
	return true

func appliquer_customisation_importee(resoudre: Callable) -> void:
	if _entite_importee_joueur == null:
		return
	for sprite in _sprites_importes:
		if sprite == null or sprite.texture == null:
			continue
		var source: Dictionary = _source_sprite(sprite)
		if source.is_empty():
			continue
		var res: Variant = resoudre.call(int(source["dossier"]), int(source["fichier"]))
		var res_array: Array = res if res is Array else []
		if res_array.is_empty():
			sprite.visible = false
			continue
		sprite.visible = true
		var cible_info: Dictionary = _loader.dossiers[res_array[0]]["fichiers"][res_array[1]]
		var texture_cible: Texture2D = _texture_cachee(String(cible_info["chemin"]))
		if texture_cible == null:
			continue
		sprite.texture = texture_cible
	_actualiser_point_bouche()

func _echouer(message: String) -> bool:
	last_error = message
	push_warning(message)
	return false

func _normaliser_nom_animation(nom: String) -> String:
	if _animation_player == null:
		return ""
	if _animation_player.has_animation(nom):
		return nom
	var avec_prefixe := _prefixe_lib_anim + nom
	if _animation_player.has_animation(avec_prefixe):
		return avec_prefixe
	return ""

func _sur_animation_finie(nom: StringName) -> void:
	animation_terminee.emit(String(nom).trim_prefix(_prefixe_lib_anim))

func _indexer_infos_fichiers() -> void:
	_infos_par_chemin.clear()
	for id_dossier in _loader.dossiers.keys():
		var dossier: Dictionary = _loader.dossiers[id_dossier]
		var fichiers: Dictionary = dossier["fichiers"]
		for id_fichier in fichiers.keys():
			var info: Dictionary = fichiers[id_fichier]
			var chemin := _normaliser_chemin_ressource(String(info["chemin"]))
			_infos_par_chemin[chemin] = {
				"dossier": int(id_dossier),
				"fichier": int(id_fichier)
			}

func _source_sprite(sprite: Sprite2D) -> Dictionary:
	var ressource_path := _normaliser_chemin_ressource(String(sprite.texture.resource_path))
	var chemin := ""
	if sprite.has_meta("source_scml_path"):
		chemin = String(sprite.get_meta("source_scml_path"))
	elif _infos_par_chemin.has(ressource_path):
		chemin = ressource_path
		sprite.set_meta("source_scml_path", chemin)
	else:
		return {}
	return _infos_par_chemin.get(chemin, {})

func _texture_cachee(chemin: String) -> Texture2D:
	var normalise := _normaliser_chemin_ressource(chemin)
	if _textures_cache.has(normalise):
		return _textures_cache[normalise]
	var texture := load(normalise) as Texture2D
	_textures_cache[normalise] = texture
	return texture

func _normaliser_chemin_ressource(chemin: String) -> String:
	return chemin.replace("\\", "/")

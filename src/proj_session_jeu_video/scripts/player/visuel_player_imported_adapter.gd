class_name VisuelPlayerImportedAdapter
extends RefCounted

signal animation_terminee(nom: String)
var last_error := ""

var _hote: Node2D
var _prefixe_lib_anim := ""
var _loader: SpriterLoader
var _scene_importee: Node = null
var _entite_importee_joueur: Node2D = null
var _animation_player: AnimationPlayer = null
var _sprites_armes := {}
var _sprites_importes: Array = []
var _infos_par_chemin := {}
var _textures_cache := {}


func initialiser(
		hote: Node2D,
		chemin_scml: String,
		nom_entite_joueur: String,
		prefixe_lib_anim: String,
		loader: SpriterLoader) -> bool:
	_hote = hote
	_prefixe_lib_anim = prefixe_lib_anim
	_loader = loader
	last_error = ""
	_indexer_infos_fichiers()

	var scene := load(chemin_scml) as PackedScene
	if scene == null:
		return _echouer("Impossible de charger la scène SCML importée: " + chemin_scml)

	_scene_importee = scene.instantiate()
	if _scene_importee == null:
		return _echouer("Impossible d'instancier la scène SCML importée: " + chemin_scml)

	_hote.add_child(_scene_importee)
	_entite_importee_joueur = _trouver_entite_joueur(nom_entite_joueur)
	if _entite_importee_joueur == null:
		var nom_racine: String = _scene_importee.name if _scene_importee != null else "<null>"
		var noms_enfants: String = _noms_enfants(_scene_importee)
		_detruire_scene_importee()
		return _echouer(
			"Entité SCML '%s' introuvable. Racine=%s, enfants directs=%s" % [
				nom_entite_joueur,
				nom_racine,
				noms_enfants
			]
		)

	_isoler_entites_non_joueur()

	_animation_player = _entite_importee_joueur.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animation_player == null:
		_animation_player = _scene_importee.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animation_player == null:
		_detruire_scene_importee()
		return _echouer("AnimationPlayer introuvable dans la scène SCML importée.")

	_animation_player.animation_finished.connect(_sur_animation_finie)
	_collecter_sprites_importes()
	return true


func _echouer(message: String) -> bool:
	last_error = message
	push_warning(message)
	return false


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
	return nom_anim


func position_animation_ms() -> float:
	if _animation_player == null:
		return 0.0
	return _animation_player.current_animation_position * 1000.0


func position_bouche(bouche_y: float, noms_sprites_armes: Array, fallback: Vector2) -> Vector2:
	var arme_importee := _sprite_arme_importe(noms_sprites_armes)
	if arme_importee == null or arme_importee.texture == null:
		return fallback
	var taille_importee := arme_importee.texture.get_size()
	return arme_importee.to_global(arme_importee.offset + Vector2(taille_importee.x, taille_importee.y * bouche_y))


func appliquer_customisation_importee(resoudre: Callable) -> void:
	if _entite_importee_joueur == null:
		return
	for sprite_t in _sprites_importes:
		var sprite: Sprite2D = sprite_t
		if sprite == null or sprite.texture == null:
			continue
		var source: Dictionary = _source_sprite(sprite)
		if source.is_empty():
			continue
		var res = resoudre.call(int(source["dossier"]), int(source["fichier"]))
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
	var nom_str := String(nom)
	if nom_str.begins_with(_prefixe_lib_anim):
		nom_str = nom_str.trim_prefix(_prefixe_lib_anim)
	animation_terminee.emit(nom_str)


func _sprite_arme_importe(noms_sprites_armes: Array) -> Sprite2D:
	if _entite_importee_joueur == null:
		return null
	for nom_t in noms_sprites_armes:
		var nom := String(nom_t)
		if _sprites_armes.has(nom):
			return _sprites_armes[nom]
		var sprite := _entite_importee_joueur.find_child(nom, true, false) as Sprite2D
		if sprite != null:
			_sprites_armes[nom] = sprite
			return sprite
	return null


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


func _collecter_sprites_importes() -> void:
	_sprites_importes.clear()
	if _entite_importee_joueur == null:
		return
	_collecter_sprites_recursive(_entite_importee_joueur)


func _collecter_sprites_recursive(noeud: Node) -> void:
	if noeud is Sprite2D:
		_sprites_importes.append(noeud)
	for enfant in noeud.get_children():
		_collecter_sprites_recursive(enfant)


func _source_sprite(sprite: Sprite2D) -> Dictionary:
	var ressource_path := _normaliser_chemin_ressource(String(sprite.texture.resource_path))
	var chemin := ""
	if _infos_par_chemin.has(ressource_path):
		chemin = ressource_path
		sprite.set_meta("source_scml_path", chemin)
	elif sprite.has_meta("source_scml_path"):
		chemin = String(sprite.get_meta("source_scml_path"))
	else:
		return {}

	var info = _infos_par_chemin.get(chemin, {})
	return info if info is Dictionary else {}


func _texture_cachee(chemin: String) -> Texture2D:
	var normalise := _normaliser_chemin_ressource(chemin)
	if _textures_cache.has(normalise):
		return _textures_cache[normalise]
	var texture := load(normalise) as Texture2D
	_textures_cache[normalise] = texture
	return texture


func _normaliser_chemin_ressource(chemin: String) -> String:
	return chemin.replace("\\", "/")


func _isoler_entites_non_joueur() -> void:
	if _scene_importee == null or _entite_importee_joueur == null:
		return
	if _entite_importee_joueur == _scene_importee:
		return
	for enfant in _scene_importee.get_children():
		if enfant == _entite_importee_joueur:
			continue
		if enfant is Node and enfant.is_ancestor_of(_entite_importee_joueur):
			continue
		if enfant is CanvasItem:
			(enfant as CanvasItem).visible = false


func _trouver_entite_joueur(nom_entite_joueur: String) -> Node2D:
	if _scene_importee == null:
		return null
	var trouvee := _scene_importee.find_child(nom_entite_joueur, true, false) as Node2D
	if trouvee != null:
		return trouvee
	if _scene_importee is Node2D:
		var racine := _scene_importee as Node2D
		var ap_racine := racine.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap_racine != null:
			return racine
	for enfant in _scene_importee.get_children():
		var candidat := enfant as Node2D
		if candidat == null:
			continue
		var ap := candidat.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap != null:
			return candidat
	return null


func _noms_enfants(noeud: Node) -> String:
	if noeud == null:
		return "[]"
	var noms: Array[String] = []
	for enfant in noeud.get_children():
		noms.append(enfant.name)
	return str(noms)


func _detruire_scene_importee() -> void:
	if _scene_importee != null:
		_scene_importee.queue_free()
	_scene_importee = null
	_entite_importee_joueur = null
	_animation_player = null

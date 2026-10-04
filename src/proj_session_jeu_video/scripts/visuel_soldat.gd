class_name VisuelSoldat
extends Node2D

signal animation_terminee(nom: String)

const CHEMIN_SCML := "res://assets/sprites/sprites_joueur/Spriter.scml"

var vitesse := 1.0
var nom_animation := ""

var _loader := SpriterLoader.new()
var _donnees := SpriterAnimations.new()
var _os := {}        # id de timeline -> Node2D
var _pieces := {}    # id de timeline -> Sprite2D
var _anim: Dictionary = {}
var _temps := 0.0    # en millisecondes
var _fini := false


func _ready() -> void:
	_loader.charger_images(CHEMIN_SCML)
	_donnees.charger(CHEMIN_SCML)
	_construire_squelette()
	jouer("Idle")


func jouer(nom: String, relancer := false) -> void:
	if nom == nom_animation and not relancer:
		return
	if not _donnees.animations.has(nom):
		push_error("Animation inconnue : " + nom)
		return
	nom_animation = nom
	_anim = _donnees.animations[nom]
	_temps = 0.0
	_fini = false
	_appliquer(0.0)


func _process(delta: float) -> void:
	if _anim.is_empty() or _fini:
		return
	_temps += delta * 1000.0 * vitesse
	var longueur: int = _anim["longueur"]
	if _temps >= longueur:
		if _anim["boucle"]:
			_temps = fmod(_temps, longueur)
		else:
			_temps = longueur - 1.0   # reste figé sur la dernière pose
			_fini = true
			animation_terminee.emit(nom_animation)
	_appliquer(_temps)


# ---------- Construction (une seule fois) ----------

func _construire_squelette() -> void:
	var ref_anim: Dictionary = _donnees.animations["Idle"]
	var cle: Dictionary = ref_anim["mainline"][0]
	var tls: Dictionary = ref_anim["timelines"]
	var os_par_ref := {}   # id du bone_ref -> Node2D

	for ref in cle["os"]:
		var id_tl := int(ref["timeline"])
		var n := Node2D.new()
		n.name = tls[id_tl]["nom"]
		var id_parent := int(ref.get("parent", -1))
		var parent: Node = self if id_parent == -1 else os_par_ref[id_parent]
		parent.add_child(n)
		os_par_ref[int(ref["id"])] = n
		_os[id_tl] = n

	for ref in cle["objets"]:
		var id_tl := int(ref["timeline"])
		var s := Sprite2D.new()
		s.name = "piece_%d" % id_tl
		s.centered = false
		os_par_ref[int(ref["parent"])].add_child(s)
		_pieces[id_tl] = s


# ---------- Animation (à chaque image) ----------

func _appliquer(t: float) -> void:
	var longueur: int = _anim["longueur"]
	var boucle: bool = _anim["boucle"]
	var tls: Dictionary = _anim["timelines"]

	# Clé du mainline en vigueur : elle donne l'ordre d'affichage (z_index)
	var cle_main: Dictionary = _anim["mainline"][0]
	for c in _anim["mainline"]:
		if c["temps"] <= t:
			cle_main = c

	for ref in cle_main["os"]:
		var id_tl := int(ref["timeline"])
		_poser(_os[id_tl], _valeurs(tls[id_tl], t, longueur, boucle))

	for ref in cle_main["objets"]:
		var id_tl := int(ref["timeline"])
		var v := _valeurs(tls[id_tl], t, longueur, boucle)
		var s: Sprite2D = _pieces[id_tl]
		_poser(s, v)
		s.z_index = int(ref["z_index"])
		_mettre_image(s, v)


func _valeurs(tl: Dictionary, t: float, longueur: int, boucle: bool) -> Dictionary:
	var cles: Array = tl["cles"]
	var i := 0
	for k in cles.size():
		if cles[k]["temps"] <= t:
			i = k

	var j := i + 1
	var temps_b: float
	if j < cles.size():
		temps_b = cles[j]["temps"]
	elif boucle:
		j = 0
		temps_b = longueur + cles[0]["temps"]
	else:
		return cles[i]["attrs"]

	var cle_a: Dictionary = cles[i]
	if j == i or temps_b == cle_a["temps"] or cle_a["courbe"] == "instant":
		return cle_a["attrs"]

	var r: float = (t - float(cle_a["temps"])) / (temps_b - float(cle_a["temps"]))
	var a: Dictionary = cle_a["attrs"]
	var b: Dictionary = cles[j]["attrs"]

	var res := a.duplicate()
	res["x"] = lerpf(_f(a, "x", 0.0), _f(b, "x", 0.0), r)
	res["y"] = lerpf(_f(a, "y", 0.0), _f(b, "y", 0.0), r)
	res["scale_x"] = lerpf(_f(a, "scale_x", 1.0), _f(b, "scale_x", 1.0), r)
	res["scale_y"] = lerpf(_f(a, "scale_y", 1.0), _f(b, "scale_y", 1.0), r)
	res["angle"] = _angle(_f(a, "angle", 0.0), _f(b, "angle", 0.0), cle_a["spin"], r)
	if a.has("pivot_x") and b.has("pivot_x"):
		res["pivot_x"] = lerpf(float(a["pivot_x"]), float(b["pivot_x"]), r)
		res["pivot_y"] = lerpf(float(a["pivot_y"]), float(b["pivot_y"]), r)
	return res


func _angle(a: float, b: float, spin: int, r: float) -> float:
	if spin == 0:
		return a
	if spin > 0 and b - a < 0.0:
		b += 360.0
	if spin < 0 and b - a > 0.0:
		b -= 360.0
	return a + (b - a) * r


func _f(d: Dictionary, nom: String, defaut: float) -> float:
	return float(d[nom]) if d.has(nom) else defaut


func _poser(n: Node2D, v: Dictionary) -> void:
	n.position = Vector2(_f(v, "x", 0.0), -_f(v, "y", 0.0))
	n.rotation = -deg_to_rad(_f(v, "angle", 0.0))
	n.scale = Vector2(_f(v, "scale_x", 1.0), _f(v, "scale_y", 1.0))


func _mettre_image(s: Sprite2D, v: Dictionary) -> void:
	var info: Dictionary = _loader.dossiers[int(v["folder"])]["fichiers"][int(v["file"])]
	if s.get_meta("chemin", "") != info["chemin"]:
		s.texture = load(info["chemin"])
		s.set_meta("chemin", info["chemin"])
	var pivot: Vector2 = info["pivot"]
	if v.has("pivot_x"):
		pivot.x = float(v["pivot_x"])
	if v.has("pivot_y"):
		pivot.y = float(v["pivot_y"])
	s.offset = Vector2(-info["largeur"] * pivot.x, -info["hauteur"] * (1.0 - pivot.y))

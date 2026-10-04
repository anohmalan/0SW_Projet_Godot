class_name JoueurBuilder
extends RefCounted

# Construit le soldat dans sa pose de départ (clé 0 de l'animation « Idle »).
static func construire(loader: SpriterLoader, chemin_scml: String, racine: Node2D) -> void:
	var anim := _lire_animation(chemin_scml, "Idle")
	var os_par_id := {}   # id du bone_ref -> Node2D

	# 1. Les os (les parents apparaissent toujours avant leurs enfants)
	for ref in anim["bone_refs"]:
		var tl: Dictionary = anim["timelines"][int(ref["timeline"])]
		var os := Node2D.new()
		os.name = tl["nom"]                        # ex. « bone_001 »
		_appliquer_transformation(os, tl["attrs"])
		var id_parent := int(ref.get("parent", -1))
		var parent: Node = racine if id_parent == -1 else os_par_id[id_parent]
		parent.add_child(os)
		os_par_id[int(ref["id"])] = os

	# 2. Les pièces (images)
	for ref in anim["object_refs"]:
		var id_tl := int(ref["timeline"])
		var tl: Dictionary = anim["timelines"][id_tl]
		var a: Dictionary = tl["attrs"]
		var info: Dictionary = loader.dossiers[int(a["folder"])]["fichiers"][int(a["file"])]

		var sprite := Sprite2D.new()
		sprite.name = "piece_%d" % id_tl
		sprite.texture = load(info["chemin"])
		sprite.centered = false

		# Le pivot de la clé remplace celui du fichier s'il est présent.
		var pivot: Vector2 = info["pivot"]
		if a.has("pivot_x"): pivot.x = float(a["pivot_x"])
		if a.has("pivot_y"): pivot.y = float(a["pivot_y"])
		# pivot_y est mesuré depuis le BAS de l'image dans Spriter.
		sprite.offset = Vector2(-info["largeur"] * pivot.x, -info["hauteur"] * (1.0 - pivot.y))

		_appliquer_transformation(sprite, a)
		sprite.z_index = int(ref["z_index"])
		sprite.set_meta("dossier", int(a["folder"]))   # utile pour la personnalisation
		sprite.set_meta("fichier", int(a["file"]))
		os_par_id[int(ref["parent"])].add_child(sprite)


# Conversion Spriter -> Godot : l'axe Y est inversé, donc l'angle aussi.
static func _appliquer_transformation(n: Node2D, a: Dictionary) -> void:
	n.position = Vector2(float(a.get("x", 0)), -float(a.get("y", 0)))
	n.rotation = -deg_to_rad(float(a.get("angle", 0)))
	n.scale = Vector2(float(a.get("scale_x", 1)), float(a.get("scale_y", 1)))


static func _attributs(parser: XMLParser) -> Dictionary:
	var d := {}
	for i in parser.get_attribute_count():
		d[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
	return d


# Lit, pour l'entité « Char » et l'animation demandée : les références de la
# première clé du mainline, et les valeurs de la première clé de chaque timeline.
static func _lire_animation(chemin: String, nom_anim: String) -> Dictionary:
	var parser := XMLParser.new()
	parser.open(chemin)
	var resultat := {"bone_refs": [], "object_refs": [], "timelines": {}}
	var dans_char := false
	var dans_anim := false
	var dans_mainline := false
	var cle_mainline := -1
	var tl_courante := -1
	var cle_tl := -1

	while parser.read() == OK:
		var type := parser.get_node_type()
		if type == XMLParser.NODE_ELEMENT_END:
			var fin := parser.get_node_name()
			if fin == "animation" and dans_anim:
				break
			if fin == "mainline":
				dans_mainline = false
			continue
		if type != XMLParser.NODE_ELEMENT:
			continue

		match parser.get_node_name():
			"entity":
				dans_char = parser.get_named_attribute_value_safe("name") == "Char"
			"animation":
				dans_anim = dans_char and parser.get_named_attribute_value_safe("name") == nom_anim
			"mainline":
				dans_mainline = dans_anim
				cle_mainline = -1
			"timeline":
				if dans_anim:
					tl_courante = int(parser.get_named_attribute_value("id"))
					cle_tl = -1
					resultat["timelines"][tl_courante] = {
						"nom": parser.get_named_attribute_value("name"),
						"attrs": {}
					}
			"key":
				if dans_mainline:
					cle_mainline += 1
				elif dans_anim and tl_courante >= 0:
					cle_tl += 1
			"bone_ref":
				if dans_mainline and cle_mainline == 0:
					resultat["bone_refs"].append(_attributs(parser))
			"object_ref":
				if dans_mainline and cle_mainline == 0:
					resultat["object_refs"].append(_attributs(parser))
			"bone", "object":
				if dans_anim and not dans_mainline and cle_tl == 0:
					resultat["timelines"][tl_courante]["attrs"] = _attributs(parser)
	return resultat
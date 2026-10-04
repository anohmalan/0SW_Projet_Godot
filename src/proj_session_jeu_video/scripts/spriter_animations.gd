class_name SpriterAnimations
extends RefCounted

const IGNOREES := ["Climb"]   # squelette différent, inutile pour ce jeu

var cartes: Dictionary = {}          # nom -> Array de règles
var _carte_courante: Array = []

# animations[nom] = { nom, longueur, boucle, mainline: [...], timelines: {...} }
var animations: Dictionary = {}

func charger(chemin: String, nom_entite: String = "Char") -> bool:
	var parser := XMLParser.new()
	if parser.open(chemin) != OK:
		push_error("Impossible d'ouvrir : " + chemin)
		return false

	var dans_entite := false
	var dans_mainline := false
	var anim: Dictionary = {}
	var cle_main: Dictionary = {}
	var tl: Dictionary = {}
	var cle_tl: Dictionary = {}

	while parser.read() == OK:
		var type := parser.get_node_type()

		if type == XMLParser.NODE_ELEMENT_END:
			match parser.get_node_name():
				"mainline":
					dans_mainline = false
				"animation":
					if not anim.is_empty():
						animations[anim["nom"]] = anim
						anim = {}
				"entity":
					if dans_entite:
						break
			continue

		if type != XMLParser.NODE_ELEMENT:
			continue

		var a := _attributs(parser)
		match parser.get_node_name():
			"entity":
				dans_entite = a.get("name", "") == nom_entite
			"animation":
				if dans_entite and not IGNOREES.has(a["name"]):
					anim = {
						"nom": a["name"],
						"longueur": int(a["length"]),
						"boucle": a.get("looping", "true") != "false",
						"mainline": [],
						"timelines": {}
					}
					tl = {}
					cle_tl = {}
			"mainline":
				dans_mainline = not anim.is_empty()
			"key":
				if not anim.is_empty():
					if dans_mainline:
						cle_main = {"temps": int(a.get("time", 0)), "os": [], "objets": []}
						anim["mainline"].append(cle_main)
					elif not tl.is_empty():
						cle_tl = {
							"temps": int(a.get("time", 0)),
							"spin": int(a.get("spin", 1)),
							"courbe": a.get("curve_type", "linear"),
							"attrs": {}
						}
						tl["cles"].append(cle_tl)
			"bone_ref":
				if dans_mainline:
					cle_main["os"].append(a)
			"object_ref":
				if dans_mainline:
					cle_main["objets"].append(a)
			"timeline":
				if not anim.is_empty():
					tl = {"nom": a["name"], "cles": []}
					anim["timelines"][int(a["id"])] = tl
					cle_tl = {}
			"character_map":
				if dans_entite:
					_carte_courante = []
					cartes[a["name"]] = _carte_courante
			"map":
				if dans_entite:
					_carte_courante.append({
						"dossier": int(a["folder"]),
						"fichier": int(a["file"]),
						"cible_dossier": int(a.get("target_folder", -1)),
						"cible_fichier": int(a.get("target_file", -1))
					})
			"bone", "object":
				if not anim.is_empty() and not dans_mainline and not cle_tl.is_empty():
					cle_tl["attrs"] = a
	return true


func _attributs(parser: XMLParser) -> Dictionary:
	var d := {}
	for i in parser.get_attribute_count():
		d[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
	return d
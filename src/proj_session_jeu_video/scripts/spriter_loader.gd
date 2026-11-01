class_name SpriterLoader
extends RefCounted

# Structure : dossiers[id_dossier] = { "nom": String, "fichiers": { id_fichier: {...} } }
var dossiers: Dictionary = {}
var dossier_base: String = ""

func charger_images(chemin_scml: String) -> bool:
	dossier_base = chemin_scml.get_base_dir()
	var parser := XMLParser.new()
	if parser.open(chemin_scml) != OK:
		push_error("Impossible d'ouvrir : " + chemin_scml)
		return false

	var id_dossier := -1
	while parser.read() == OK:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"folder":
				id_dossier = int(parser.get_named_attribute_value("id"))
				dossiers[id_dossier] = {
					"nom": parser.get_named_attribute_value("name"),
					"fichiers": {}
				}
			"file":
				var id_fichier := int(parser.get_named_attribute_value("id"))
				var nom := parser.get_named_attribute_value("name")
				dossiers[id_dossier]["fichiers"][id_fichier] = {
					"chemin": dossier_base + "/" + nom,
					"largeur": int(parser.get_named_attribute_value("width")),
					"hauteur": int(parser.get_named_attribute_value("height")),
					"pivot": Vector2(
						float(parser.get_named_attribute_value("pivot_x")),
						float(parser.get_named_attribute_value("pivot_y")))
				}
			"entity":
				break   # on s'arrête avant les animations
	return true
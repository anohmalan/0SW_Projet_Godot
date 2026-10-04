extends Node

func _ready() -> void:
	var loader := SpriterLoader.new()
	if not loader.charger_images("res://assets/sprites/sprites_joueur/Spriter.scml"):
		return

	var total := 0
	var manquants := 0
	for id_d in loader.dossiers:
		if id_d > 9:
			continue   # dossiers 10 à 13 : effets, importés plus tard
		var d: Dictionary = loader.dossiers[id_d]
		total += d["fichiers"].size()
		print(id_d, " ", d["nom"], " : ", d["fichiers"].size(), " fichiers")
		for id_f in d["fichiers"]:
			if not ResourceLoader.exists(d["fichiers"][id_f]["chemin"]):
				manquants += 1
				print("  MANQUANT : ", d["fichiers"][id_f]["chemin"])

	print("Total (dossiers 0 à 9) : ", total, " fichiers, manquants : ", manquants)
	print(loader.dossiers[0]["fichiers"][0])
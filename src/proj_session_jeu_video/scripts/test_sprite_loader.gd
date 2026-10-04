extends Node2D

func _ready() -> void:
	var chemin := "res://assets/sprites/sprites_joueur/Spriter.scml"
	var loader := SpriterLoader.new()
	loader.charger_images(chemin)

	var joueur := Node2D.new()
	joueur.name = "Joueur"
	add_child(joueur)
	JoueurBuilder.construire(loader, chemin, joueur)
	joueur.position = Vector2(576, 360)   # milieu de la fenêtre 1152 x 648
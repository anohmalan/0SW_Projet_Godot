extends Node2D

@onready var joueur: Joueur = $Joueur
@onready var pool: PoolBalles = $PoolBalles

func _ready() -> void:
	joueur.tir_demande.connect(
		func(pos, dir, arme): pool.tirer(pos, dir, arme, true))
	joueur.vie_changee.connect(func(v, m): print("Vie : ", v, " / ", m))
	joueur.arme_changee.connect(func(a, m):
		print("Arme : ", a.nom, " (munitions : ",
			"illimitées" if m < 0 else str(m), ")"))
	joueur.munitions_changees.connect(func(m): print("Munitions : ", m))
	joueur.est_mort.connect(func(): print("Le joueur est mort"))
	joueur.rafraichir()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H:
				joueur.recevoir_degats(20)
			KEY_G:
				for i in joueur.armes.size():
					joueur.ajouter_munitions(i, 99)
			KEY_R:
				get_tree().reload_current_scene()
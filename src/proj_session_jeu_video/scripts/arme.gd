class_name Arme
extends Resource

@export var nom := ""
@export var carte := ""            # carte du soldat (vide = fusil d'assaut d'origine)
@export var cadence := 0.15        # secondes entre deux tirs
@export var degats := 10
@export var portee := 500.0        # pixels
@export var vitesse_balle := 900.0
@export var projectiles := 1       # plusieurs pour le fusil à pompe
@export var dispersion := 0.0      # demi-angle de dispersion, en degrés
@export var munitions_max := -1    # -1 = illimitées
@export var bouche_y := 0.3        # hauteur du bout du canon dans l'image (0 = haut, 1 = bas)
@export var couleur := Color(1.0, 0.85, 0.2)

static func catalogue() -> Array[Arme]:
	var liste: Array[Arme] = []
	liste.append(_nouvelle({
		"nom": "Fusil d'assaut", "carte": "", "cadence": 0.12, "degats": 8,
		"portee": 520.0, "vitesse_balle": 900.0, "projectiles": 1,
		"dispersion": 2.0, "munitions_max": -1, "bouche_y": 0.288,
		"couleur": Color(1.0, 0.85, 0.2)}))
	liste.append(_nouvelle({
		"nom": "Fusil à pompe", "carte": "Gun - Shotgun 1", "cadence": 0.6, "degats": 6,
		"portee": 280.0, "vitesse_balle": 800.0, "projectiles": 6,
		"dispersion": 14.0, "munitions_max": 24, "bouche_y": 0.241,
		"couleur": Color(1.0, 0.55, 0.2)}))
	liste.append(_nouvelle({
		"nom": "Fusil de précision", "carte": "Gun - Sniper", "cadence": 0.9, "degats": 45,
		"portee": 1100.0, "vitesse_balle": 1600.0, "projectiles": 1,
		"dispersion": 0.0, "munitions_max": 12, "bouche_y": 0.484,
		"couleur": Color(0.6, 0.9, 1.0)}))
	return liste


static func _nouvelle(valeurs: Dictionary) -> Arme:
	var a := Arme.new()
	for cle in valeurs:
		a.set(cle, valeurs[cle])
	return a
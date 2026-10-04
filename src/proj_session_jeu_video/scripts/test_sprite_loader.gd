extends Node2D

const ANIMS := ["Idle", "Idle_Aim", "Walk", "Run", "Run_Aim",
		"Jump", "Jump_Aim", "Shoot", "Hurt", "Dead"]
const CATEGORIES := ["Head", "Balaclava", "Mask", "Googles", "Head Gear",
		"Shirt", "Jacket", "Pants", "Gun"]

var _indices := {}   # catégorie -> index (-1 = origine)
var _i := 0

@onready var visuel: VisuelSoldat = $Visuel

func _ready() -> void:
	visuel.position = Vector2(576, 360)
	visuel.animation_terminee.connect(func(nom): print("Terminée : ", nom))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			_cycler(event.keycode - KEY_1)
			return
		if event.keycode == KEY_0:
			visuel.appliquer_apparence({
				"Pants": "Pants - Brown", "Shirt": "Shirt - Camo",
				"Head Gear": "Head Gear - Green Baret", "Googles": "Googles - None",
				"Jacket": "Jacket - None", "Mask": "Mask - None",
				"Balaclava": "Balaclava - None"})
			return
		match event.keycode:
			KEY_RIGHT:
				_i = (_i + 1) % ANIMS.size()
				visuel.jouer(ANIMS[_i])
				print(ANIMS[_i])
			KEY_LEFT:
				_i = (_i - 1 + ANIMS.size()) % ANIMS.size()
				visuel.jouer(ANIMS[_i])
				print(ANIMS[_i])
			KEY_R:
				visuel.jouer(ANIMS[_i], true)

func _cycler(i_cat: int) -> void:
	var cat: String = CATEGORIES[i_cat]
	var options := visuel.variantes(cat)
	var idx: int = _indices.get(cat, -1) + 1
	if idx >= options.size():
		idx = -1
	_indices[cat] = idx
	visuel.definir_carte(cat, "" if idx == -1 else options[idx])
	print(cat, " -> ", "origine" if idx == -1 else options[idx])
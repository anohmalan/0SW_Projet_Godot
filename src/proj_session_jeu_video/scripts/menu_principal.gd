extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_jouer_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/choisir_niveau.tscn")


func _on_quitter_pressed() -> void:
	get_tree().quit()


func _on_réglages_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/replages.tscn")

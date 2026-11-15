extends AnimatedSprite2D

## Effet ponctuel : joue l'animation une fois puis disparaît.

func _ready() -> void:
	animation_finished.connect(queue_free)
	play(&"default")

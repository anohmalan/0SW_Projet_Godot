@abstract class_name BaseState
extends Node

# Signal pour annoncer un changement d’état
signal Transitioned

@abstract func handle_inputs(input_event: InputEvent) -> void
@abstract func update(delta: float) -> void
@abstract func physics_update(delta: float) -> void
@abstract func enter() -> void
@abstract func exit() -> void
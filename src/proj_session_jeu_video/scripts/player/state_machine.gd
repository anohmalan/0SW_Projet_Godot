class_name StateMachine
extends Node

@export var initial_state : BaseState
var current_state : BaseState
var states : Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is BaseState:
			var state_name := child.name.to_lower()
			if states.has(state_name):
				push_error("Duplicate state name: %s" % child.name)
				return
			states[state_name] = child
			child.Transitioned.connect(on_child_transition)
	
	if initial_state == null or initial_state.get_parent() != self:
		push_error("StateMachine requires an initial_state among its children.")
		return
	current_state = initial_state
	current_state.enter()

func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_inputs(event)
	
func _process(delta: float) -> void:
	update(delta)

func update(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	physics_update(delta)

func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func on_child_transition(state: BaseState, new_state_name: StringName) -> void:
	if state != current_state:
		return
	change_state(new_state_name)

func change_state(new_state_name: StringName) -> void:
	var new_state: BaseState = states.get(String(new_state_name).to_lower())
	
	if !new_state:
		push_error("Unknown state: %s" % new_state_name)
		return

	if new_state == current_state:
		return
		
	if current_state:
		current_state.exit()
		
	current_state = new_state
	current_state.enter()

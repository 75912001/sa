class_name StateMachine
extends Node

var current_state: StateBase

func change_state(new_state: StateBase) -> void:
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()
	
func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

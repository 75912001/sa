extends Node

class_name StateBase


signal state_finished(next_state_name: String)

var player: CharacterBody3D
var state_machine: StateMachine

func enter() -> void:
	pass
func exit() -> void:
	pass
func physics_update(_delta: float) -> void:
	pass

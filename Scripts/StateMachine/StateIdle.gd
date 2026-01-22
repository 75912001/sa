class_name StateIdle
extends StateBase

func physics_update(_delta: float) -> void:
	var input = Input.get_vector("left", "right", "up", "down")
	if 0 < input.length():
		state_finished.emit("MoveState")

class_name StateMove
extends StateBase

func physics_update (delta: float) -> void:
	var input = Input.get_vector("left","right","up","down")
	if input.length() == 0:
		state_finished.emit("Idlestate")
		return
	player.handle_movement(input, delta)

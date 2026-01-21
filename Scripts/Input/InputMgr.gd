# 输入-管理器
class_name InputMgr

extends Node

var move_vector: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	# 移动输入
	move_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

# 如果需要阻断输入(例如打开菜单时), 可以在这里加开关
func get_move_vector() -> Vector2:
	return move_vector

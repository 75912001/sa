# 输入-管理器
class_name InputMgr extends IInputProvider

# 移动
var move_vector: Vector2 = Vector2.ZERO
# 切换-左手
var switch_left_hand_pressed: bool = false
# 切换-右手
var switch_right_hand_pressed: bool = false
# 攻击-右手
var attack_right_pressed: bool = false
# 攻击-左手（未来扩展）
var attack_left_pressed: bool = false
# 跳
var jump_pressed: bool = false
# 翻滚
var roll_pressed: bool = false

func _process(_delta: float) -> void:
	# 移动输入
	move_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	# 切换-左手
	switch_left_hand_pressed = Input.is_action_just_pressed("switch_left_hand")
	# 切换-右手
	switch_right_hand_pressed = Input.is_action_just_pressed("switch_right_hand")
	# 攻击-右手
	attack_right_pressed = Input.is_action_just_pressed("attack_right")
	# 攻击-左手（暂未绑定按键）
	attack_left_pressed = false
	# 跳
	jump_pressed = Input.is_action_just_pressed("jump")
	# 翻滚
	roll_pressed = Input.is_action_just_pressed("roll")

# 如果需要阻断输入, 可以在这里加开关
func get_move_vector() -> Vector2:
	return move_vector

# 如果需要阻断输入, 可以在这里加开关
func get_switch_left_hand_pressed() -> bool:
	return switch_left_hand_pressed

# 如果需要阻断输入, 可以在这里加开关
func get_switch_right_hand_pressed() -> bool:
	return switch_right_hand_pressed

# 如果需要阻断输入, 可以在这里加开关
func get_attack_right_pressed() -> bool:
	return attack_right_pressed

# 如果需要阻断输入, 可以在这里加开关
func get_attack_left_pressed() -> bool:
	return attack_left_pressed

# 如果需要阻断输入, 可以在这里加开关
func get_jump_pressed() -> bool:
	return jump_pressed
	
# 如果需要阻断输入, 可以在这里加开关
func get_roll_pressed() -> bool:
	return roll_pressed

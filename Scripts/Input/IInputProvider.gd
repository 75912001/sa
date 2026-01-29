# IInputProvider.gd - 输入提供者接口
#
# 所有提供输入的对象都应继承这个类
# - InputMgr：从玩家按键获取输入
# - AIInputMgr：从AI决策获取输入
#
# 优点：
# ✓ Character不需要知道输入来源（玩家还是AI）
# ✓ 各管理器只需调用统一接口
# ✓ 易于扩展新的输入源（如网络、重放等）
#
# 使用示例：
#   var input: IInputProvider = input_mgr  # Player的InputMgr
#   var direction = input.get_move_vector()  # 获取移动方向
#
#   var ai_input: IInputProvider = ai_input_mgr  # NPC的AIInputMgr
#   var direction = ai_input.get_move_vector()  # 同样的调用，不同的源

class_name IInputProvider extends Node

# 获取移动方向向量 (-1 ~ 1)
func get_move_vector() -> Vector2:
	return Vector2.ZERO

# 检查是否按下右手攻击
func get_attack_right_pressed() -> bool:
	return false

# 检查是否按下左手攻击（未来扩展）
func get_attack_left_pressed() -> bool:
	return false

# 检查是否按下翻滚
func get_roll_pressed() -> bool:
	return false

# 检查是否按下跳跃
func get_jump_pressed() -> bool:
	return false

# 检查是否按下切换右手武器
func get_switch_right_hand_pressed() -> bool:
	return false

# 检查是否按下切换左手武器
func get_switch_left_hand_pressed() -> bool:
	return false

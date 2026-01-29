# AIInputMgr.gd - AI输入管理器
#
# 模拟玩家输入，但输入来自AI决策而不是玩家按键
# 所有AI系统通过设置ai_decision字典来控制角色行为
#
# 使用示例：
#   var ai_input = AIInputMgr.new()
#   ai_input.set_move_direction(Vector2.UP)     # AI决定向上移动
#   ai_input.set_attack_right(true)             # AI决定攻击
#
#   var direction = ai_input.get_move_vector()  # 返回 Vector2.UP
#   var attack = ai_input.get_attack_right_pressed()  # 返回 true
#
# 优点：
# ✓ 所有AI系统使用统一的接口
# ✓ NPC系统完全复用Player的所有管理器
# ✓ 易于扩展其他AI行为

class_name AIInputMgr extends IInputProvider

# AI决策存储 - 由AI控制器每帧更新
var ai_decision: Dictionary = {
	"move_direction": Vector2.ZERO,
	"attack_right": false,
	"attack_left": false,
	"roll": false,
	"jump": false,
	"switch_right": false,
	"switch_left": false,
}

# ============= Setter 方法 =============
# 由AI控制器调用这些方法来设置决策

## 设置移动方向（-1 ~ 1）
func set_move_direction(direction: Vector2) -> void:
	ai_decision["move_direction"] = direction.normalized()

## 设置是否右手攻击
func set_attack_right(value: bool) -> void:
	ai_decision["attack_right"] = value

## 设置是否左手攻击
func set_attack_left(value: bool) -> void:
	ai_decision["attack_left"] = value

## 设置是否翻滚
func set_roll(value: bool) -> void:
	ai_decision["roll"] = value

## 设置是否跳跃
func set_jump(value: bool) -> void:
	ai_decision["jump"] = value

## 设置是否切换右手武器
func set_switch_right(value: bool) -> void:
	ai_decision["switch_right"] = value

## 设置是否切换左手武器
func set_switch_left(value: bool) -> void:
	ai_decision["switch_left"] = value

# ============= Getter 方法 =============
# 实现IInputProvider的接口
# 各管理器通过这些方法查询AI决策

func get_move_vector() -> Vector2:
	return ai_decision.get("move_direction", Vector2.ZERO)

func get_attack_right_pressed() -> bool:
	return ai_decision.get("attack_right", false)

func get_attack_left_pressed() -> bool:
	return ai_decision.get("attack_left", false)

func get_roll_pressed() -> bool:
	return ai_decision.get("roll", false)

func get_jump_pressed() -> bool:
	return ai_decision.get("jump", false)

func get_switch_right_hand_pressed() -> bool:
	return ai_decision.get("switch_right", false)

func get_switch_left_hand_pressed() -> bool:
	return ai_decision.get("switch_left", false)

# ============= 调试方法 =============

## 清除所有决策（恢复为不动作状态）
func clear_all_decisions() -> void:
	ai_decision = {
		"move_direction": Vector2.ZERO,
		"attack_right": false,
		"attack_left": false,
		"roll": false,
		"jump": false,
		"switch_right": false,
		"switch_left": false,
	}

## 获取当前所有决策（用于调试）
func get_all_decisions() -> Dictionary:
	return ai_decision.duplicate()

extends Node
# 动画-管理器
class_name AnimationMgr

# --- 配置 ---
@export var animation_tree_path: NodePath

# --- 变量 ---
var _animation_tree: AnimationTree
var _state_machine: AnimationNodeStateMachinePlayback
var _current_animation_name := "" # 当前动画

func _ready() -> void:
	_animation_tree = get_node(animation_tree_path)
	if _animation_tree:
		_animation_tree.active = true
	_state_machine = _animation_tree.get("parameters/playback")

# 播放指定动画
func play(animation_name: String) -> void:
	if _current_animation_name != animation_name:
		_current_animation_name = animation_name
		_state_machine.travel(animation_name)

# 根据状态更新动画
# 移动
# 有-武器
# 跳跃
# 空中
func update(is_moving: bool, has_weapon: bool, is_jumping: bool, is_airborne: bool) -> void:
	# 跳跃状态优先
	if is_jumping or is_airborne:
		# TODO: 添加持剑跳跃动画后根据 has_weapon 区分
		play("Unarmed_Jump")
		return

	# 根据武器状态选择动画
	if has_weapon:
		if is_moving:
			play("SwordAndShield_Walk")
		else:
			play("SwordAndShield_Idle")
	else:
		if is_moving:
			play("Unarmed_Walking")
		else:
			play("Unarmed_Idle")

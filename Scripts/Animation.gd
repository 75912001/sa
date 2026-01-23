# 动画-管理器
class_name AnimationMgr

extends Node

# --- 配置 ---
@export var animation_tree_path: NodePath

# --- 信号 ---
signal animation_finished(animation_name: String)

# --- 变量 ---
var _animation_tree: AnimationTree
var _state_machine: AnimationNodeStateMachinePlayback
var _current_animation_name := "" # 当前动画

func _ready() -> void:
	_animation_tree = get_node(animation_tree_path)
	if _animation_tree:
		_animation_tree.active = true
		# 连接动画完成信号
		_animation_tree.animation_finished.connect(_on_animation_finished)
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
# todo menglc 这里的update,将多个状态混合, 是否会越来越复杂
func update(is_moving: bool, has_weapon: bool, is_jumping: bool, is_airborne: bool) -> void:
	# 优化思路: 将动画名称拆分为 [姿态]_[行为] 的组合
	# 姿态 (Stance): Unarmed, SwordAndShield, TwoHandedSword...
	# 行为 (Action): Idle, Walk, Run, Jump...

	var stance := "Unarmed"
	if has_weapon:
		stance = "SwordAndShield" # 这里后续可以根据 weapon_type 扩展

	var action := "Idle"
	if is_jumping or is_airborne:
		action = "Jump"
	elif is_moving:
		# TODO: 建议统一动画命名。目前 Unarmed 是 Walking, Sword 是 Walk
		action = "Walking" if stance == "Unarmed" else "Walk"

	play(stance + "_" + action)

# 动画完成回调
func _on_animation_finished(anim_name: StringName) -> void:
	animation_finished.emit(str(anim_name))

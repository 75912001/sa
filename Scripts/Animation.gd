# 动画-管理器
class_name AnimationMgr

extends Node

# --- 配置 ---
@export var animation_tree_path: NodePath

# --- 信号 ---
signal animation_finished(animation_name: String)
signal lower_animation_finished(animation_name: String)
signal upper_animation_finished(animation_name: String)

# --- 引用（在 Player.gd 中设置）---
var weapon_switch_mgr: WeaponSwitchMgr
var movement_mgr: MovementMgr

# --- 动画模式 ---
enum AnimMode { 
	SPLIT, # 分离模式
	FULL_BODY # 全身模式
}

# --- 变量 ---
var _animation_tree: AnimationTree
var _lower_body_sm: AnimationNodeStateMachinePlayback
var _upper_body_sm: AnimationNodeStateMachinePlayback
var _current_mode := AnimMode.SPLIT
var _current_lower := ""
var _current_upper := ""

func _ready() -> void:
	_animation_tree = get_node(animation_tree_path)
	if _animation_tree:
		_animation_tree.active = true
		# 连接动画完成信号
		_animation_tree.animation_finished.connect(_on_animation_finished)
	_lower_body_sm = _animation_tree.get("parameters/lower_body_sm/playback")
	_upper_body_sm = _animation_tree.get("parameters/upper_body_sm/playback")

# ==================== 动画模式 ====================
# 设置动画模式
func set_mode(mode: AnimMode) -> void:
	_current_mode = mode
	var amount = 1.0 if mode == AnimMode.SPLIT else 0.0
	_animation_tree.set("parameters/blend/blend_amount", amount)

# 检查是否-全身模式
func is_full_body_mode() -> bool:
	return _current_mode == AnimMode.FULL_BODY
	
# 检查是否-分离模式
func is_split_mode() -> bool:
	return _current_mode == AnimMode.SPLIT

# ==================== 分离模式 ====================
# 播放下半身动画
func play_lower(animation_name: String) -> void:
	if _current_lower != animation_name:
		_current_lower = animation_name
		_lower_body_sm.travel(animation_name)

# 播放上半身动画
func play_upper(animation_name: String) -> void:
	if _current_upper != animation_name:
		_current_upper = animation_name
		_upper_body_sm.travel(animation_name)

# 同时播放上下半身
func play_split(lower: String, upper: String) -> void:
	play_lower(lower)
	play_upper(upper)

# ==================== 全身模式 ====================
# 播放全身动画（翻滚、倒地等）
func play_full_body(animation_name: String) -> void:
	set_mode(AnimMode.FULL_BODY)
	_current_lower = animation_name
	_lower_body_sm.travel(animation_name)

# ==================== 状态查询 ====================

# 获取当前下半身状态
func get_lower_state() -> String:
	return _lower_body_sm.get_current_node()

# 获取当前上半身状态
func get_upper_state() -> String:
	return _upper_body_sm.get_current_node()

# 检查下半身是否在播放指定动画
func is_lower_playing(animation_name: String) -> bool:
	return get_lower_state() == animation_name

# 检查上半身是否在播放指定动画
func is_upper_playing(animation_name: String) -> bool:
	return get_upper_state() == animation_name

# ==================== 回调 ====================
func _on_animation_finished(anim_name: StringName) -> void:
	animation_finished.emit(str(anim_name))


func update_lower_animation() -> void:
	if movement_mgr.is_moving():
		if GPlayerData.get_right_hand_weapon_uuid() == 0 && GPlayerData.get_left_hand_weapon_uuid() == 0:
			set_mode(AnimationMgr.AnimMode.FULL_BODY)
			play_lower("Unarmed_Walking")
		else:
			set_mode(AnimationMgr.AnimMode.SPLIT)
			play_lower("Unarmed_Walking")
	else:
		if GPlayerData.get_right_hand_weapon_uuid() == 0 && GPlayerData.get_left_hand_weapon_uuid() == 0:
			set_mode(AnimationMgr.AnimMode.FULL_BODY)
			play_lower("Unarmed_Idle")
		else:
			set_mode(AnimationMgr.AnimMode.SPLIT)
			play_lower("Unarmed_Idle")

func update_upper_animation() -> void:
	if is_full_body_mode():
		return
	# 如果没有上半身动作在播放，根据武器状态更新
	if not weapon_switch_mgr.is_switching():
		if GPlayerData.get_right_hand_weapon_uuid() != 0:
			play_upper("SwordAndShield_Idle")
		else:
			play_upper("Unarmed_Idle")

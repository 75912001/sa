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
	# 双手-空
	var is_all_unarmed = GPlayerData.get_right_hand_weapon_uuid() == 0 && GPlayerData.get_left_hand_weapon_uuid() == 0
	if movement_mgr.is_moving(): # 移动
		if is_all_unarmed: # 双手-空
			set_mode(AnimationMgr.AnimMode.FULL_BODY)
			play_lower("Unarmed_Walking")
		else: # 手持武器
			set_mode(AnimationMgr.AnimMode.SPLIT)
			play_lower("Unarmed_Walking")
		return
	if weapon_switch_mgr.is_switching(): # 换武器
		set_mode(AnimationMgr.AnimMode.SPLIT)
		play_lower("Unarmed_Idle")
		return
	#idle
	if is_all_unarmed:
		set_mode(AnimationMgr.AnimMode.FULL_BODY)
		play_lower("Unarmed_Idle")
	else:
		set_mode(AnimationMgr.AnimMode.SPLIT)
		play_lower("Unarmed_Idle")
	return

func update_upper_animation() -> void:
	if is_full_body_mode(): # 全身模式
		return
	if weapon_switch_mgr.is_switching(): # 换武器
		return
	
	# idle
	var left_weapon_type = PbWeapon.WeaponType.WeaponType_Unarmed
	var right_weapon_type = PbWeapon.WeaponType.WeaponType_Unarmed
	
	var left_weapon_cfg = GPlayerData.get_left_weapon_cfg()
	var right_weapon_cfg = GPlayerData.get_right_weapon_cfg()
	if left_weapon_cfg != null:
		left_weapon_type = left_weapon_cfg.type
	if right_weapon_cfg != null:
		right_weapon_type = right_weapon_cfg.type

	var left_is_pose_neutral_weapon = _pose_neutral_weapon(left_weapon_type)
	var right_is_pose_neutral_weapon = _pose_neutral_weapon(right_weapon_type)
	
	if left_is_pose_neutral_weapon && right_is_pose_neutral_weapon: # 武器不影响上半身动作
		play_upper("Unarmed_Idle")
		return
	else:
		play_upper("SwordAndShield_Idle")
		return

# 姿势-中立的武器 (对姿势没有影响)
func _pose_neutral_weapon(weapon_type: PbWeapon.WeaponType) -> bool:
	match weapon_type:
		PbWeapon.WeaponType.WeaponType_Unarmed:
			return true
		PbWeapon.WeaponType.WeaponType_ShortSword:
			return true
		PbWeapon.WeaponType.WeaponType_Sword:
			return true
	return false
	

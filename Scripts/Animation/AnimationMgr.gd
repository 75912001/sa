# 动画-管理器
class_name AnimationMgr
extends Node

# --- 配置 ---
@export var animation_tree_path: NodePath

# --- 信号 ---
signal animation_finished(animation_name: String)
#signal lower_animation_finished(animation_name: String)
#signal upper_animation_finished(animation_name: String)

var character_body: CharacterBody3D
# --- 引用 ---
var character: Character
var one_shot: AnimationOneShot
var lock_mgr: LockMgr  # 锁管理器

# --- 动画模式 ---
enum AnimMode {
	SPLIT, # 分离模式
	FULL_BODY # 全身模式
}

# --- 变量 ---
var animation_tree: AnimationTree
var _lower_body_sm: AnimationNodeStateMachinePlayback
var _upper_body_sm: AnimationNodeStateMachinePlayback
var _current_mode := AnimMode.SPLIT
var _current_lower := ""
var _current_upper := ""

func _ready() -> void:
	character_body = get_parent() as CharacterBody3D
	animation_tree = get_node(animation_tree_path)
	if animation_tree:
		animation_tree.active = true
		# 连接动画完成信号
		animation_tree.animation_finished.connect(_on_animation_finished)
	else:
		assert(false, "❌ AnimationMgr._ready() - 找不到 AnimationTree!")
		return
	# lock_mgr
	lock_mgr = LockMgr.new()
	# one_shot
	one_shot = AnimationOneShot.new()
	one_shot.animation_mgr = self
	one_shot.name = "AnimationOneShot"
	add_child(one_shot) # 挂载为子节点，以便它能使用 get_tree()
	one_shot.setup(self)

	_lower_body_sm = animation_tree.get("parameters/lower_body_sm/playback")
	_upper_body_sm = animation_tree.get("parameters/upper_body_sm/playback")

	if _lower_body_sm == null or _upper_body_sm == null:
		assert(false, "❌ AnimationMgr._ready() - 状态机获取失败! lower=%s, upper=%s" % [_lower_body_sm, _upper_body_sm])
	else:
		print("✓ AnimationMgr._ready() - 状态机初始化成功")

func setup(_character: Character) -> void:
	character = _character

	# 重新激活 AnimationTree，强制重新缓存轨道引用
	animation_tree.active = false
	animation_tree.active = true

	# 启动状态机
	_lower_body_sm.start("Unarmed_Idle")
	_upper_body_sm.start("Unarmed_Idle")

	# 调试：打印骨骼信息
	var bone_count = character.skeleton.get_bone_count()
	print("✓ AnimationMgr.setup() - 状态机已启动 (角色: %s)" % character.name)
	print("  🦴 骨骼数量: %d" % bone_count)
	print("  🦴 前10个骨骼:")
	for i in range(min(10, bone_count)):
		print("    [%d] %s" % [i, character.skeleton.get_bone_name(i)])

	return

func _on_one_shot_action_finished(action_name: String) -> void:
	character.attack_mgr.on_animation_one_shot_action_finished(action_name)
	return

# ==================== 动画模式 ====================
# 设置动画模式
func set_mode(mode: AnimMode) -> void:
	_current_mode = mode
	var amount = 1.0 if mode == AnimMode.SPLIT else 0.0
	animation_tree.set("parameters/blend/blend_amount", amount)

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
		# character.name 是 StringName, "null" 是 String, 需要强转以兼容三元运算符
		print("📍 play_lower(%s) - %s" % [animation_name, String(character.name) if character else "null"])

# 播放上半身动画
func play_upper(animation_name: String) -> void:
	if _current_upper != animation_name:
		_current_upper = animation_name
		_upper_body_sm.travel(animation_name)

# 同时播放上下半身
func play_split(lower: String, upper: String) -> void:
	play_lower(lower)
	play_upper(upper)

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

# 更新-动画模式
func _update_mode() -> void:
	if lock_mgr.has_lock(LockMgr.ACT_WEAPON_SWITCH): # 正在切换武器
		set_mode(AnimMode.SPLIT)
		return
	if !_pose_neutral_left_weapon() || !_pose_neutral_right_weapon(): # 左/右手武器-对姿势-有影响
		set_mode(AnimMode.SPLIT)
		return

	set_mode(AnimMode.FULL_BODY)

# 下半身
func update_lower_animation() -> void:
	_update_mode()
	if character.movement_mgr.is_moving(): # 移动
		play_lower("Unarmed_Walking")
		return
	if lock_mgr.has_lock(LockMgr.ACT_WEAPON_SWITCH): # 正在换武器
		play_lower("Unarmed_Idle")
		return
	if lock_mgr.has_lock(LockMgr.ACT_ATTACKING): # 攻击
		return
	#idle
	play_lower("Unarmed_Idle")
	if character.name == "@NPC@8" or character.name == "@NPC@9":  # 仅 NPC 输出调试
		print("🎬 [%s] update_lower_animation: mode=%s, moving=%s" % [character.name, _current_mode, character.movement_mgr.is_moving()])

# 上半身
func update_upper_animation() -> void:
	if is_full_body_mode(): # 全身模式
		return
	if lock_mgr.has_lock(LockMgr.ACT_ATTACKING): # 攻击
		return # 由 AttackMgr.gd 控制
	if lock_mgr.has_lock(LockMgr.ACT_WEAPON_SWITCH): # 正在换武器
		return # 由 WeaponSwitchMgr.gd 控制

	# idle
	assert(false, "todo menglc ... update_upper_animation idle...")
	#play_upper("SwordAndShield_Idle")
	return

# 姿势-中立的武器 - 左手 (对姿势没有影响)
func _pose_neutral_left_weapon() -> bool:
	var left_weapon_type = PbWeapon.WeaponType.WeaponType_Unarmed
	var left_weapon_cfg = GPlayerData.get_left_weapon_cfg()
	if left_weapon_cfg != null:
		left_weapon_type = left_weapon_cfg.type
	return _pose_neutral_weapon(left_weapon_type)

# 姿势-中立的武器 - 右手 (对姿势没有影响)
func _pose_neutral_right_weapon() -> bool:
	var right_weapon_type = PbWeapon.WeaponType.WeaponType_Unarmed
	var right_weapon_cfg = GPlayerData.get_right_weapon_cfg()
	if right_weapon_cfg != null:
		right_weapon_type = right_weapon_cfg.type
	return _pose_neutral_weapon(right_weapon_type)

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

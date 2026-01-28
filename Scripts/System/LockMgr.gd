# 锁管理器 - 用于控制角色动作的互斥关系
#
# 设计思路：使用"阻止列表"模式，每个动作声明它会阻止哪些其他动作
# 这样可以直观地看出"某动作进行中，哪些动作不能执行"
#
# 使用示例：
#   lock_mgr.add_lock(LockMgr.ACT_JUMPING)
#   lock_mgr.can_act(LockMgr.ACT_ATTACKING)  # → true（跳跃中可以攻击）
#   lock_mgr.can_act(LockMgr.ACT_ROLLING)    # → false（跳跃中不能翻滚）
#   lock_mgr.remove_lock(LockMgr.ACT_JUMPING)
#
class_name LockMgr
extends RefCounted

# =============================================================================
# 动作名称常量
# =============================================================================
# 使用常量避免字符串拼写错误，便于重构和 IDE 自动补全
const ACT_DEATH = "death"                # 死亡
const ACT_STAGGER = "stagger"            # 受击硬直
const ACT_ROLLING = "rolling"            # 翻滚
const ACT_ATTACKING = "attacking"        # 攻击
const ACT_JUMPING = "jumping"            # 跳跃
const ACT_WEAPON_SWITCH = "weapon_switch"  # 切换武器
const ACT_MOVE = "move"                  # 移动

# 特殊值：阻止所有动作
const BLOCK_ALL = "*"

# =============================================================================
# 阻止列表配置
# =============================================================================
# 格式：{ "动作名": ["被阻止的动作列表"] }
# 特殊值 "*" 表示阻止所有动作
#
# 维护指南：
# - 添加新动作时，先在上方添加 ACT_XXX 常量
# - 然后在此处添加一行，列出它会阻止的动作
# - 如果新动作不阻止任何动作，设为空数组 []
# - 如果新动作阻止所有动作，设为 [BLOCK_ALL]
# =============================================================================
const LOCK_BLOCKS: Dictionary = {
	# 死亡
	ACT_DEATH: [
		BLOCK_ALL,
	],
	# 硬直
	ACT_STAGGER: [
		ACT_ROLLING,
		ACT_ATTACKING,
		ACT_JUMPING,
		ACT_WEAPON_SWITCH,
		ACT_MOVE,
	],
	# 翻滚
	ACT_ROLLING: [
		ACT_ROLLING,
		ACT_ATTACKING,
		ACT_JUMPING,
		ACT_WEAPON_SWITCH,
	],
	# 攻击
	ACT_ATTACKING: [
		ACT_ROLLING,
		ACT_ATTACKING,
		ACT_JUMPING,
		ACT_WEAPON_SWITCH,
		ACT_MOVE,
	],
	# 切换武器
	ACT_WEAPON_SWITCH: [
		ACT_ROLLING,
		ACT_ATTACKING,
		ACT_JUMPING,
		ACT_WEAPON_SWITCH,
	],
	# 跳跃
	ACT_JUMPING: [
		ACT_ROLLING,
		ACT_JUMPING,
		ACT_WEAPON_SWITCH,
	],
	# 移动
	ACT_MOVE:[
	],
}

# =============================================================================
# 内部状态
# =============================================================================
# 当前激活的锁 { "锁名": true }
# 使用 Dictionary 作为 Set，防止重复添加同名锁
var _active_locks: Dictionary = {}

# =============================================================================
# 公共 API
# =============================================================================

## 添加锁
## @param action_name: 锁的名称，必须在 LOCK_BLOCKS 中定义
func add_lock(action_name: String) -> void:
	prints("add_lock ",action_name)
	if not LOCK_BLOCKS.has(action_name):
		push_warning("LockMgr: 未知的锁名称 '%s'，请在 LOCK_BLOCKS 中定义" % action_name)
	_active_locks[action_name] = true

## 移除锁
## @param action_name: 要移除的锁名称
func remove_lock(action_name: String) -> void:
	prints("remove_lock ",action_name)
	if not LOCK_BLOCKS.has(action_name):
		push_warning("LockMgr: 未知的锁名称 '%s'，请在 LOCK_BLOCKS 中定义" % action_name)
	_active_locks.erase(action_name)

# 是否有-动作-锁
func has_lock(action_name: String) -> bool:
	if not LOCK_BLOCKS.has(action_name):
		push_warning("LockMgr: 未知的锁名称 '%s'，请在 LOCK_BLOCKS 中定义" % action_name)
	return _active_locks.has(action_name)

## 检查是否可以执行某个动作
## @param action_name: 想要执行的动作名称
## @return: true 表示可以执行，false 表示被阻止
func can_act(action_name: String) -> bool:
	if not LOCK_BLOCKS.has(action_name):
		push_warning("LockMgr: 未知的锁名称 '%s'，请在 LOCK_BLOCKS 中定义" % action_name)
	# 遍历所有激活的锁，检查是否有任何锁阻止该动作
	for lock_name in _active_locks.keys():
		if _is_blocked_by(lock_name, action_name):
			return false
	return true

## 检查是否有任何锁处于激活状态
## @return: true 表示有锁，false 表示无锁
func is_locked() -> bool:
	return not _active_locks.is_empty()

## 获取当前所有激活的锁（用于调试）
## @return: 锁名称数组
func get_active_locks() -> Array:
	return _active_locks.keys()

## 清除所有锁（谨慎使用，一般用于角色重置/重生）
func clear_all() -> void:
	_active_locks.clear()

# =============================================================================
# 内部方法
# =============================================================================

## 检查某个锁是否阻止某个动作
## @param lock_name: 锁的名称
## @param action_name: 动作的名称
## @return: true 表示该锁阻止该动作
func _is_blocked_by(lock_name: String, action_name: String) -> bool:
	var blocked_list: Array = LOCK_BLOCKS[lock_name]

	# 检查是否阻止所有动作
	if blocked_list.has(BLOCK_ALL):
		return true

	# 检查是否在阻止列表中
	return blocked_list.has(action_name)

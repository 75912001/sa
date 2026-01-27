class_name AttackMgr
extends Node

@export var input_mgr: InputMgr
@export var anim_tree: AnimationTree

# --- 信号 ---
signal attack_started()
signal attack_ended()

# --- 状态 ---
enum State {
	IDLE, # 空闲
	ATTACKING, # 攻击中
}

# --- 变量 ---
var _state: State = State.IDLE

# --- 引用（在 Player.gd 中设置）---
var animation_mgr: AnimationMgr
var weapon_switch_mgr: WeaponSwitchMgr
var movement_mgr: MovementMgr

# OneShot 节点路径
const ANIM_PATH_REQUEST = "parameters/Action_OneShot/request"

func _process(delta: float) -> void:
	# 模拟测试打断 (比如按了 空格)
	if input_mgr.get_jump_pressed():
		interrupt()
	if not _can_attack(): # 不能攻击
		return
	if input_mgr.get_attack_right_pressed(): # 攻击-右手
		attack()

# 强制打断
func interrupt() -> void:
	# 检查当前是否正在攻击等逻辑...
	# REQUEST_FADE_OUT: 立即停止当前动作，并根据 Fade Out Time 平滑过渡到底层(Idle/Walk)
	anim_tree.set(ANIM_PATH_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
	# 或者使用 REQUEST_ABORT (生硬切断，通常不推荐，除非是受击瞬间切入受击状态)
	# anim_tree.set(ANIM_PATH_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	print("攻击-被打断")
	_state = State.IDLE
	movement_mgr.remove_lock("attack")
	attack_ended.emit()

# 执行攻击 (自然播放)
func attack() -> void:
	# REQUEST_FIRE: 从头开始播放，播完自动切回底层
	anim_tree.set(ANIM_PATH_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	print("攻击-开始")
	_state = State.ATTACKING
	movement_mgr.add_lock("attack")
	attack_started.emit()

func _can_attack() -> bool:
	if GPlayerData.get_right_hand_weapon_uuid() == 0: # 右手没有武器
		return false
	# 正在攻击中
	if is_attacking():
		return false
	# 正在切换武器
	if weapon_switch_mgr.is_switching():
		return false
	return true

## 是否正在攻击
func is_attacking() -> bool:
	return _state == State.ATTACKING

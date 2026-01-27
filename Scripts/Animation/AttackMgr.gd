class_name AttackMgr
extends Node

@export var input_mgr: InputMgr
@export var anim_tree: AnimationTree
@export var animation_mgr: AnimationMgr

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
var weapon_switch_mgr: WeaponSwitchMgr
var movement_mgr: MovementMgr

# OneShot 节点路径
const ANIM_PATH_REQUEST = "parameters/Action_OneShot/request"
const ANIM_PATH_ACTIVE = "parameters/Action_OneShot/active"

func _ready() -> void:
	# 监听 OneShot 的完成信号，统一处理结束
	animation_mgr.one_shot.action_ended.connect(_on_action_ended)

func _process(delta: float) -> void:
	if input_mgr.get_jump_pressed(): # 模拟测试-打断 (比如按了 空格)
		animation_mgr.one_shot.stop()
	if not _can_attack(): # 不能攻击
		return
	if input_mgr.get_attack_right_pressed(): # 攻击-右手
		attack()

# 执行攻击 (自然播放)
func attack() -> void:
	animation_mgr.one_shot.play("attack")
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

# 统一的回调：当 OneShot 结束时触发
func _on_action_ended(action_name: String) -> void:
	# 只有当前是攻击状态，且结束的动作是 "attack" 时才处理
	if _state == State.ATTACKING and action_name == "attack":
		_finish_attack_logic()
		
# 结束攻击逻辑
func _finish_attack_logic() -> void:
	print("攻击-结束")
	_state = State.IDLE
	movement_mgr.remove_lock("attack")
	attack_ended.emit()

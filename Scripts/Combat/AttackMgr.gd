class_name AttackMgr
extends Node

@export var input_mgr: InputMgr

# --- 信号 ---
signal attack_started()
signal attack_finished()

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

func handle_input() -> void:
	if !input_mgr.get_attack_right_pressed():
		return
	if not _can_attack(): # 不能攻击
		return
	_do_attack()

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

func _do_attack() -> void:
	_state = State.ATTACKING
	attack_started.emit()

	# 播放攻击动画
	animation_mgr.play_upper("SwordAndShield_Attack_Slash_2_8")
	await animation_mgr.animation_finished

	# 检查节点是否仍然有效
	if not is_instance_valid(self):
		return

	_state = State.IDLE
	# 手动切换回 Idle
	animation_mgr.play_upper("SwordAndShield_Idle")
	attack_finished.emit()

## 是否正在攻击
func is_attacking() -> bool:
	return _state == State.ATTACKING

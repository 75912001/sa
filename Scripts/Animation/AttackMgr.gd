class_name AttackMgr
extends Node

# --- 信号 ---
signal attack_started()
signal attack_ended()

# --- 引用（在 Player.gd 中设置）---
var animation_mgr: AnimationMgr

func _process(delta: float) -> void:
	if animation_mgr.input_mgr.get_jump_pressed(): # 模拟测试-打断 (比如按了 空格)
		animation_mgr.one_shot.stop()
	if not _can_attack(): # 不能攻击
		return
	if animation_mgr.input_mgr.get_attack_right_pressed(): # 攻击-右手
		attack()

func setup() -> void:
	animation_mgr.one_shot.action_finished.connect(_on_action_finished)

# 执行攻击 (自然播放)
func attack() -> void:
	animation_mgr.one_shot.play("attack")
	print("攻击-开始 state: attacking")
	animation_mgr.lock_mgr.add_lock(LockMgr.ACT_ATTACKING)
	attack_started.emit()

func _can_attack() -> bool:
	if !animation_mgr.lock_mgr.can_act(LockMgr.ACT_ATTACKING):
		return false
	if GPlayerData.get_right_hand_weapon_uuid() == 0: # 右手没有武器
		return false
	return true

# 统一的回调：当 OneShot 结束时触发
func _on_action_finished(action_name: String) -> void:
	# 只有当前是攻击状态，且结束的动作是 "attack" 时才处理
	if action_name == "attack":
		print("攻击-结束 state: idle")
		animation_mgr.lock_mgr.remove_lock(LockMgr.ACT_ATTACKING)
		attack_ended.emit()

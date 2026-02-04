class_name AttackMgr
extends Node

# --- 信号 ---
signal attack_started()
signal attack_finished()

# --- 引用（在 Player.gd 中设置）---
var animation_mgr: AnimationMgr

# 原始动画时长（秒）- 与 Animation 资源一致
const ATTACK_ANIMATION_DURATION := 1.5

func _process(delta: float) -> void:
func _process(_delta: float) -> void:
	if animation_mgr.input_mgr.get_jump_pressed(): # 模拟测试-打断 (比如按了 空格)
		animation_mgr.one_shot.stop()
	if !animation_mgr.lock_mgr.can_act(LockMgr.ACT_ATTACKING):
		return
	if GPlayerData.get_right_hand_weapon_uuid() == 0: # 右手没有武器
		return
	if animation_mgr.input_mgr.get_attack_right_pressed(): # 攻击-右手
		attack()

func setup() -> void:
	animation_mgr.one_shot.action_finished.connect(_on_action_finished)

# 执行攻击
func attack() -> void:
	var speed_scale = _calculate_attack_speed()
	animation_mgr.one_shot.play("attack", speed_scale)
	print("攻击-开始 speed_scale:", speed_scale)
	animation_mgr.lock_mgr.add_lock(LockMgr.ACT_ATTACKING)
	attack_started.emit()

# 统一的回调：当 OneShot 结束时触发
func _on_action_finished(action_name: String) -> void:
	# 只有当前是攻击状态，且结束的动作是 "attack" 时才处理
	if action_name == "attack":
		print("攻击-结束 state: idle")
		animation_mgr.lock_mgr.remove_lock(LockMgr.ACT_ATTACKING)
		attack_finished.emit()


# 计算攻击动画速度
func _calculate_attack_speed() -> float:
	var weapon_cfg = GPlayerData.get_right_weapon_cfg()
	if weapon_cfg == null:
		return 1.0
	# 如果未配置时长，使用原始速度
	if weapon_cfg.attack_duration_ms <= 0:
		return 1.0
	# 速度 = 原始时长 / 目标时长
	var target_duration = weapon_cfg.attack_duration_ms / 1000.0
	return ATTACK_ANIMATION_DURATION / target_duration

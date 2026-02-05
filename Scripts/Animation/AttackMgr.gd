class_name AttackMgr
extends Node

# --- 信号 ---
signal attack_started()
signal attack_finished()

# --- 引用（在 Player.gd 中设置）---
var character: Character

# 原始动画时长（秒）- 与 Animation 资源一致
const ATTACK_ANIMATION_DURATION := 1.5

func _process(_delta: float) -> void:
	if not character.animation_mgr:
		return
	if character.input_mgr.get_jump_pressed(): # 模拟测试-打断 (比如按了 空格)
		character.animation_mgr.one_shot.stop()
	if !character.animation_mgr.lock_mgr.can_act(LockMgr.ACT_ATTACKING):
		return
	if GPlayerData.get_right_hand_weapon_uuid() == 0: # 右手没有武器
		return
	if character.input_mgr.get_attack_right_pressed(): # 攻击-右手
		attack()

func setup(_character: Character) -> void:
	character = _character
	# 连接信号
	attack_started.connect(_on_attack_started)
	attack_finished.connect(_on_attack_finished)
	return

# 执行攻击
func attack() -> void:
	var speed_scale = _calculate_attack_speed()
	character.animation_mgr.one_shot.play("attack", speed_scale)
	print("攻击-开始 speed_scale:", speed_scale)
	character.animation_mgr.lock_mgr.add_lock(LockMgr.ACT_ATTACKING)
	attack_started.emit()

# 统一的回调：当 OneShot 结束时触发
func on_animation_one_shot_action_finished(action_name: String) -> void:
	# 只有当前是攻击状态，且结束的动作是 "attack" 时才处理
	if action_name == "attack":
		print("攻击-结束 state: idle")
		character.animation_mgr.lock_mgr.remove_lock(LockMgr.ACT_ATTACKING)
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


func _on_attack_started() -> void:
	pass

func _on_attack_finished() -> void:
	pass

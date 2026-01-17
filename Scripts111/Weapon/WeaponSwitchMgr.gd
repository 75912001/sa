extends Node
class_name WeaponSwitchMgr
## 武器切换管理器 - 编排切换动画序列（支持打断）

# --- 信号 ---
signal switch_started()
signal switch_completed()

# --- 状态 ---
enum State { 
	IDLE, # 空闲
	SWITCHING, # 切换中 
}

# --- 变量 ---
var _state: State = State.IDLE
var _target_slot: int = 0
var _switch_id: int = 0  # 用于检测打断

# --- 引用（在 Player.gd 中设置）---
var animation_mgr: AnimationMgr
var weapon_mgr: WeaponMgr
var movement_mgr: MovementMgr

# --- 时序配置（秒）---
const SHEATH_UNEQUIP_DELAY := 0.6  # 收剑动画多久后卸下武器

func handle_input() -> void:
	if Input.is_key_pressed(KEY_ALT): # Alt
		var number_key = _get_number_key_pressed()
		if number_key == -1: # 没有按数字键
			return
		_start_switch(number_key)

## 开始武器切换
func _start_switch(target_slot: int) -> bool:
	var switch_type = _get_switch_type(target_slot)
	if switch_type.is_empty(): # 没有切换类型
		return false

	# 递增 ID，之前的协程检测到 ID 变化后会停止
	_switch_id += 1
	var current_id = _switch_id

	_state = State.SWITCHING
	_target_slot = target_slot
	switch_started.emit()

	# 根据类型执行对应流程
	match switch_type:
		"unarmed_to_sword":
			_do_unarmed_to_sword(current_id)
		"sword_to_sword":
			_do_sword_to_sword(current_id)
		"sword_to_unarmed":
			_do_sword_to_unarmed(current_id)

	return true

## 检查是否被打断
func _is_interrupted(id: int) -> bool:
	return id != _switch_id

## 流程：空手 → 持剑
func _do_unarmed_to_sword(id: int) -> void:
	# 1. 空手去握剑柄
	animation_mgr.play("Unarmed_DrawSword")
	await animation_mgr.animation_finished
	if not is_instance_valid(self):
		return
	if _is_interrupted(id): return

	# 2. 装备武器模型
	weapon_mgr.equip_weapon(_target_slot)

	# 3. 拔剑动画
	animation_mgr.play("SwordAndShield_DrawSword")
	await animation_mgr.animation_finished
	if _is_interrupted(id): return

	_finish_switch()

## 流程：持剑 → 持剑（换武器）
func _do_sword_to_sword(id: int) -> void:
	# 1. 收剑动画
	animation_mgr.play("SwordAndShield_SheathSword_1")

	# 2. 延迟后卸下当前武器
	await get_tree().create_timer(SHEATH_UNEQUIP_DELAY).timeout
	if _is_interrupted(id): return
	weapon_mgr.unequip_weapon()

	await animation_mgr.animation_finished
	if _is_interrupted(id): return

	# 3. 装备新武器
	weapon_mgr.equip_weapon(_target_slot)

	# 4. 拔剑动画
	animation_mgr.play("SwordAndShield_DrawSword")
	await animation_mgr.animation_finished
	if _is_interrupted(id): return

	_finish_switch()

## 流程：持剑 → 空手
func _do_sword_to_unarmed(id: int) -> void:
	# 1. 收剑动画
	animation_mgr.play("SwordAndShield_SheathSword_1")

	# 2. 延迟后卸下武器
	await get_tree().create_timer(SHEATH_UNEQUIP_DELAY).timeout
	if not is_instance_valid(self):
		return
	if _is_interrupted(id): return
	weapon_mgr.unequip_weapon()

	await animation_mgr.animation_finished
	if _is_interrupted(id): return

	# 3. 手臂归位动画
	animation_mgr.play("SwordAndShield_SheathSword_2")
	await animation_mgr.animation_finished
	if _is_interrupted(id): return

	_finish_switch()

## 完成切换
func _finish_switch() -> void:
	_state = State.IDLE
	switch_completed.emit()

## 是否正在切换
func is_switching() -> bool:
	return _state == State.SWITCHING

## 获取切换类型
func _get_switch_type(target_slot: int) -> String:
	var has_current = weapon_mgr.has_weapon()
	var has_target := false
	if target_slot <= 0:
		has_target = false
	else:
		if weapon_mgr.has_slot(target_slot):
			has_target = true
		else:
			has_target = false
	if not has_current and has_target:
		return "unarmed_to_sword"
	if has_current and has_target:
		if weapon_mgr.get_current_slot() == target_slot:# 当前的 == 目标的
			return "sword_to_unarmed"
		# 当前的 != 目标的
		return "sword_to_sword"
	if has_current and not has_target:
		return "sword_to_unarmed"
	push_warning("weapon switch no case")
	return ""

## 检测按下的数字键，返回 0-9，未按下返回 -1
func _get_number_key_pressed() -> int:
	if Input.is_key_pressed(KEY_0): return 0
	if Input.is_key_pressed(KEY_1): return 1
	if Input.is_key_pressed(KEY_2): return 2
	if Input.is_key_pressed(KEY_3): return 3
	if Input.is_key_pressed(KEY_4): return 4
	if Input.is_key_pressed(KEY_5): return 5
	if Input.is_key_pressed(KEY_6): return 6
	if Input.is_key_pressed(KEY_7): return 7
	if Input.is_key_pressed(KEY_8): return 8
	if Input.is_key_pressed(KEY_9): return 9
	return -1

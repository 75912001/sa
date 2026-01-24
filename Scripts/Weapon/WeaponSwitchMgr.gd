# 武器-切换管理器 - 编排切换动画序列（支持打断）
class_name WeaponSwitchMgr

extends Node

@export var input_mgr: InputMgr

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
var _target_weapon_uuid: int = 0  # 目标武器 UUID
var _switch_id: int = 0  # 用于检测打断

# --- 引用（在 Player.gd 中设置）---
var animation_mgr: AnimationMgr
var weapon_mgr: WeaponMgr
var movement_mgr: MovementMgr

# --- 时序配置（秒）---
const SHEATH_UNEQUIP_DELAY := 0.6  # 收剑动画多久后卸下武器

func handle_input() -> void:
	if input_mgr.get_switch_right_hand_pressed():
		_handle_switch_right_hand()

func _handle_switch_right_hand() -> void:
	var next_uuid = GPlayerData.get_next_right_hand_weapon_uuid()
	if next_uuid == 0: # 切换->空
		_start_switch(next_uuid)
		prints("WeaponSwitchMgr: 没有可切换的武器")
		return
	prints("WeaponSwitchMgr 切换-右手 UUID:", next_uuid)
	_start_switch(next_uuid)

## 开始武器切换
func _start_switch(target_uuid: int) -> bool:
	var switch_type = _get_switch_type(target_uuid)
	if switch_type == PbWeapon.WeaponSwitchType.WeaponSwitchType_Unarmed_To_Unarmed: # 空->空
		return false

	# 递增 ID，之前的协程检测到 ID 变化后会停止
	_switch_id += 1
	var current_id = _switch_id

	_state = State.SWITCHING
	_target_weapon_uuid = target_uuid
	switch_started.emit()

	# 根据类型执行对应流程
	match switch_type:
		PbWeapon.WeaponSwitchType.WeaponSwitchType_Unarmed_To_Weapon:
			_do_unarmed_to_weapon(current_id)
		PbWeapon.WeaponSwitchType.WeaponSwitchType_Weapon_To_Weapon:
			_do_weapon_to_weapon(current_id)
		PbWeapon.WeaponSwitchType.WeaponSwitchType_Weapon_To_Unarmed:
			_do_weapon_to_unarmed(current_id)

	return true

## 检查是否被打断
func _is_interrupted(id: int) -> bool:
	return id != _switch_id

## 流程：空手 → 持剑
func _do_unarmed_to_weapon(id: int) -> void:
	# 1. 空手去握剑柄
	animation_mgr.play_upper("Unarmed_DrawSword")
	await animation_mgr.animation_finished
	if not is_instance_valid(self):
		return
	if _is_interrupted(id): return

	# 2. 装备武器模型
	weapon_mgr.equip_weapon_by_uuid(_target_weapon_uuid)
	# 更新存档中的当前右手武器
	GPlayerData.set_right_hand_weapon_uuid(_target_weapon_uuid)

	# 3. 拔剑动画
	animation_mgr.play_upper("SwordAndShield_DrawSword")
	await animation_mgr.animation_finished
	if _is_interrupted(id): return

	_finish_switch()

## 流程：持剑 → 持剑（换武器）
func _do_weapon_to_weapon(id: int) -> void:
	# 1. 收剑动画
	animation_mgr.play("SwordAndShield_SheathSword_1")

	# 2. 延迟后卸下当前武器
	await get_tree().create_timer(SHEATH_UNEQUIP_DELAY).timeout
	if _is_interrupted(id): return
	weapon_mgr.unequip_weapon()

	await animation_mgr.animation_finished
	if _is_interrupted(id): return

	# 3. 装备新武器
	weapon_mgr.equip_weapon_by_uuid(_target_weapon_uuid)
	# 更新存档中的当前右手武器
	GPlayerData.set_right_hand_weapon_uuid(_target_weapon_uuid)

	# 4. 拔剑动画
	animation_mgr.play("SwordAndShield_DrawSword")
	await animation_mgr.animation_finished
	if _is_interrupted(id): return

	_finish_switch()

## 流程：持剑 → 空手
func _do_weapon_to_unarmed(id: int) -> void:
	# 1. 收剑动画
	animation_mgr.play_upper("SwordAndShield_SheathSword_1")

	# 2. 延迟后卸下武器
	await get_tree().create_timer(SHEATH_UNEQUIP_DELAY).timeout
	if not is_instance_valid(self):
		return
	if _is_interrupted(id): return
	weapon_mgr.unequip_weapon()
	# 更新存档中的当前右手武器为空
	GPlayerData.set_right_hand_weapon_uuid(0)

	await animation_mgr.animation_finished
	if _is_interrupted(id): return

	# 3. 手臂归位动画
	animation_mgr.play_upper("SwordAndShield_SheathSword_2")
	await animation_mgr.animation_finished
	if _is_interrupted(id): return

	_finish_switch()

## 完成切换
func _finish_switch() -> void:
	_state = State.IDLE
	switch_completed.emit()

func can_switch_weapon() -> bool:
	return true

## 是否正在切换
func is_switching() -> bool:
	return _state == State.SWITCHING

## 获取切换类型
func _get_switch_type(target_uuid: int) -> PbWeapon.WeaponSwitchType:
	var right_hand_weapon_uuid = GPlayerData.get_right_hand_weapon_uuid()
	if target_uuid == 0: # 目标为空手
		if right_hand_weapon_uuid != 0:
			return PbWeapon.WeaponSwitchType.WeaponSwitchType_Weapon_To_Unarmed
		return PbWeapon.WeaponSwitchType.WeaponSwitchType_Unarmed_To_Unarmed
	if right_hand_weapon_uuid == 0: # 当前为空手
		return PbWeapon.WeaponSwitchType.WeaponSwitchType_Unarmed_To_Weapon
	if right_hand_weapon_uuid == target_uuid: # 当前武器 == 目标武器，切换为空手
		return PbWeapon.WeaponSwitchType.WeaponSwitchType_Weapon_To_Unarmed
	# 当前武器 != 目标武器
	return PbWeapon.WeaponSwitchType.WeaponSwitchType_Weapon_To_Weapon

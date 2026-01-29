# 武器-切换管理器
class_name WeaponSwitchMgr
extends Node

# --- 信号 ---
signal switch_started()
signal switch_finished()

# --- 变量 ---
var _target_weapon_uuid: int = 0  # 目标武器 UUID

# --- 引用（在 Player.gd 中设置）---
var animation_mgr: AnimationMgr
var weapon_mgr: WeaponMgr

# --- 时序配置（秒）---
const SHEATH_UNEQUIP_DELAY := 0.6  # 收剑动画多久后卸下武器

func _process(_delta: float) -> void:
	if !animation_mgr.lock_mgr.can_act(LockMgr.ACT_WEAPON_SWITCH):
		return
	if animation_mgr.input_mgr.get_switch_right_hand_pressed():
		_handle_switch_right_hand()

func _handle_switch_right_hand() -> void:
	var next_uuid = GPlayerData.get_next_right_hand_weapon_uuid()
	if next_uuid == 0: # 切换->空
		_start_switch(next_uuid)
		return
	prints("WeaponSwitchMgr 切换-右手 UUID:", next_uuid)
	_start_switch(next_uuid)

## 开始武器切换
func _start_switch(target_uuid: int) -> bool:
	var switch_type = _get_switch_type(target_uuid)
	if switch_type == PbWeapon.WeaponSwitchType.WeaponSwitchType_Unarmed_To_Unarmed: # 空->空
		return false

	animation_mgr.set_mode(AnimationMgr.AnimMode.SPLIT)

	_target_weapon_uuid = target_uuid
	animation_mgr.lock_mgr.add_lock(LockMgr.ACT_WEAPON_SWITCH)
	switch_started.emit()

	# 根据类型执行对应流程
	match switch_type:
		PbWeapon.WeaponSwitchType.WeaponSwitchType_Unarmed_To_Weapon:
			_do_unarmed_to_weapon()
		PbWeapon.WeaponSwitchType.WeaponSwitchType_Weapon_To_Weapon:
			_do_weapon_to_weapon()
		PbWeapon.WeaponSwitchType.WeaponSwitchType_Weapon_To_Unarmed:
			_do_weapon_to_unarmed()

	return true

## 流程：空手 → 持剑
func _do_unarmed_to_weapon() -> void:
	# 空手去握剑柄
	animation_mgr.play_upper("Unarmed_DrawSword")
	await animation_mgr.animation_finished
	if not is_instance_valid(self):
		_finish_switch()
		return

	# 装备武器模型
	weapon_mgr.equip_weapon_by_uuid(_target_weapon_uuid)
	# 更新存档中的当前右手武器
	GPlayerData.set_right_hand_weapon_uuid(_target_weapon_uuid)

	# 拔剑动画
	animation_mgr.play_upper("SwordAndShield_DrawSword")
	await animation_mgr.animation_finished
	if not is_instance_valid(self):
		_finish_switch()
		return
	_finish_switch()

## 流程：持剑 → 持剑（换武器）
func _do_weapon_to_weapon() -> void:
	# 收剑动画
	animation_mgr.play_upper("SwordAndShield_SheathSword_1")

	# 延迟后卸下当前武器
	await get_tree().create_timer(SHEATH_UNEQUIP_DELAY).timeout
	if not is_instance_valid(self):
		_finish_switch()
		return
	weapon_mgr.unequip_weapon()

	await animation_mgr.animation_finished
	if not is_instance_valid(self):
		_finish_switch()
		return

	# 装备新武器
	weapon_mgr.equip_weapon_by_uuid(_target_weapon_uuid)
	# 更新存档中的当前右手武器
	GPlayerData.set_right_hand_weapon_uuid(_target_weapon_uuid)

	# 4. 拔剑动画
	animation_mgr.play_upper("SwordAndShield_DrawSword")
	await animation_mgr.animation_finished
	if not is_instance_valid(self):
		_finish_switch()
		return

	_finish_switch()

## 流程：持剑 → 空手
func _do_weapon_to_unarmed() -> void:
	# 收剑动画
	animation_mgr.play_upper("SwordAndShield_SheathSword_1")

	# 延迟后卸下武器
	await get_tree().create_timer(SHEATH_UNEQUIP_DELAY).timeout
	if not is_instance_valid(self):
		_finish_switch()
		return
	weapon_mgr.unequip_weapon()
	# 更新存档中的当前右手武器为空
	GPlayerData.set_right_hand_weapon_uuid(0)

	# 等待收剑动画完成
	await animation_mgr.animation_finished
	if not is_instance_valid(self):
		_finish_switch()
		return

	# 手臂归位动画
	animation_mgr.play_upper("SwordAndShield_SheathSword_2")
	await animation_mgr.animation_finished
	if not is_instance_valid(self):
		_finish_switch()
		return

	_finish_switch()

## 完成切换
func _finish_switch() -> void:
	animation_mgr.lock_mgr.remove_lock(LockMgr.ACT_WEAPON_SWITCH)
	switch_finished.emit()

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

# 玩家数据-管理器
class_name PlayerDataMgr
extends Node


# 通过 UUID 获取武器记录
func get_weapon_record_by_uuid(weapon_uuid: int) -> PbCharacter.WeaponRecord:
	var weapon_map = GSave.character_record.get_WeaponRecordMap()
	if weapon_map.has(weapon_uuid):
		return weapon_map[weapon_uuid]
	else:
		assert(false, "武器 UUID:%d" % weapon_uuid)
	return null


# 通过 UUID 获取武器的 AssetID
func get_weapon_asset_id_by_uuid(weapon_uuid: int) -> int:
	var weapon_record = get_weapon_record_by_uuid(weapon_uuid)

	var base_map = weapon_record.get_RecordBaseMap()
	if base_map.has(PbAsset.AssetIDRecord.AssetIDRecord_AssetID):
		return base_map[PbAsset.AssetIDRecord.AssetIDRecord_AssetID]
	else:
		assert(false, "武器 UUID:%d" % weapon_uuid)
	return 0


# 通过 UUID 获取武器的 Cfg
func get_weapon_cfg_by_uuid(weapon_uuid: int) -> CfgWeaponMgr.CfgWeaponEntry:
	var asset_id = get_weapon_asset_id_by_uuid(weapon_uuid)
	return GCfgMgr.cfg_weapon_mgr.get_weapon(asset_id)


# ==================== 武器装备数据 ====================

# 获取武器装备数据
func _get_weapon_equipped_data():
	return GSave.character_record.get_WeaponEquippedData()


# 获取右手备选武器UUID列表
func get_right_hand_backup_list() -> Array:
	var data = _get_weapon_equipped_data()
	if data == null:
		return []
	return data.get_RightHandBackupWeaponUUIDList()


# 获取当前右手武器UUID (0=空手)
func get_right_hand_weapon_uuid() -> int:
	var data = _get_weapon_equipped_data()
	if data == null:
		return 0
	return data.get_RightHandWeaponUUID()


# 设置当前右手武器UUID
func set_right_hand_weapon_uuid(uuid: int) -> void:
	var data = _get_weapon_equipped_data()
	if data == null:
		return
	data.set_RightHandWeaponUUID(uuid)
	GSave.save()


# 获取下一个右手武器UUID (循环切换)
func get_next_right_hand_weapon_uuid() -> int:
	var backup_list = get_right_hand_backup_list()
	if backup_list.is_empty():
		return 0

	var current_uuid = get_right_hand_weapon_uuid()

	# 当前是空手，返回列表第一个
	if current_uuid == 0:
		return backup_list[0]

	# 找到当前武器在列表中的位置
	var current_index = backup_list.find(current_uuid)
	if current_index == -1:
		# 当前武器不在列表中，返回第一个
		return backup_list[0]

	# 返回下一个（循环）
	var next_index = (current_index + 1) % backup_list.size()
	return backup_list[next_index]

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

# 获取-左手-武器配置
func get_left_weapon_cfg() -> CfgWeaponMgr.CfgWeaponEntry:
	var uuid = get_left_hand_weapon_uuid()
	if uuid == 0:
		return null
	return get_weapon_cfg_by_uuid(uuid)

# 获取-右手-武器配置
func get_right_weapon_cfg() -> CfgWeaponMgr.CfgWeaponEntry:
	var uuid = get_right_hand_weapon_uuid()
	if uuid == 0:
		return null
	return get_weapon_cfg_by_uuid(uuid)

# 通过 UUID 获取护甲记录
func get_armor_record_by_uuid(armor_uuid: int) -> PbCharacter.ArmorRecord:
	var armor_map = GSave.character_record.get_ArmorRecordMap()
	if armor_map.has(armor_uuid):
		return armor_map[armor_uuid]
	else:
		assert(false, "护甲 UUID:%d" % armor_uuid)
	return null

# 通过 UUID 获取护甲的 AssetID
func get_armor_asset_id_by_uuid(armor_uuid: int) -> int:
	var armor_record = get_armor_record_by_uuid(armor_uuid)

	var base_map = armor_record.get_RecordBaseMap()
	if base_map.has(PbAsset.AssetIDRecord.AssetIDRecord_AssetID):
		return base_map[PbAsset.AssetIDRecord.AssetIDRecord_AssetID]
	else:
		assert(false, "护甲 UUID:%d" % armor_uuid)
	return 0

# 通过 UUID 获取护甲的 Cfg
func get_armor_cfg_by_uuid(armor_uuid: int) -> CfgArmorMgr.CfgArmorEntry:
	var asset_id = get_armor_asset_id_by_uuid(armor_uuid)
	return GCfgMgr.cfg_armor_mgr.get_armor(asset_id)

# ==================== 装备-武器-数据 ====================
# 获取武器装备数据
func _get_weapon_equipped_data():
	return GSave.character_record.get_WeaponEquippedData()

# 获取-左手-备选武器-UUID-列表
func get_left_hand_backup_list() ->Array:
	var data = _get_weapon_equipped_data()
	return data.get_LiftHandBackupWeaponUUIDList()

# 获取-右手-备选武器-UUID-列表
func get_right_hand_backup_list() -> Array:
	var data = _get_weapon_equipped_data()
	return data.get_RightHandBackupWeaponUUIDList()

# 获取-左手-武器-UUID (0=空手)
func get_left_hand_weapon_uuid() -> int:
	var data = _get_weapon_equipped_data()
	return data.get_LeftHandWeaponUUID()
	
# 获取-右手-武器-UUID (0=空手)
func get_right_hand_weapon_uuid() -> int:
	var data = _get_weapon_equipped_data()
	return data.get_RightHandWeaponUUID()

# 设置-左手-武器-UUID
func set_left_hand_weapon_uuid(uuid: int) -> void:
	var data = _get_weapon_equipped_data()
	data.set_LeftHandWeaponUUID(uuid)
	#GSave.save()

# 设置-右手-武器-UUID
func set_right_hand_weapon_uuid(uuid: int) -> void:
	var data = _get_weapon_equipped_data()
	data.set_RightHandWeaponUUID(uuid)
	#GSave.save()

# 获取-下一个-左手-武器-UUID (循环切换)
# 没有武器: 空手
# 只有一个武器: 武器<->空手 之间切换
# 多个武器: 按照有的武器,顺序切换
func get_next_left_hand_weapon_uuid() -> int:
	var backup_list = get_left_hand_backup_list()
	var uuid_list = [] # 有效武器UUID列表
	for uuid in backup_list:
		if uuid != 0:
			uuid_list.append(uuid)
	# 没有武器
	if uuid_list.is_empty():
		return 0

	var current_uuid = get_left_hand_weapon_uuid()
	# 只有一个武器: 武器<->空手 之间切换
	if uuid_list.size() == 1:
		if current_uuid != 0: # 武器 -> 空手
			return 0
		else: # 空手 -> 武器
			return uuid_list[0]

	# 多个武器: 按照有的武器,顺序切换
	var current_index = uuid_list.find(current_uuid)
	if current_index == -1:
		assert(false, "找不到当前武器UUID:%d 在备选列表中" % current_uuid)
		return uuid_list[0]
	var next_index = (current_index + 1) % uuid_list.size()
	return uuid_list[next_index]

# 获取-下一个-右手-武器-UUID (循环切换)
# 没有武器: 空手
# 只有一个武器: 武器<->空手 之间切换
# 多个武器: 按照有的武器,顺序切换
func get_next_right_hand_weapon_uuid() -> int:
	var backup_list = get_right_hand_backup_list()
	var uuid_list = [] # 有效武器UUID列表
	for uuid in backup_list:
		if uuid != 0:
			uuid_list.append(uuid)
	# 没有武器
	if uuid_list.is_empty():
		return 0

	var current_uuid = get_right_hand_weapon_uuid()
	# 只有一个武器: 武器<->空手 之间切换
	if uuid_list.size() == 1:
		if current_uuid != 0: # 武器 -> 空手
			return 0
		else: # 空手 -> 武器
			return uuid_list[0]

	# 多个武器: 按照有的武器,顺序切换
	var current_index = uuid_list.find(current_uuid)
	if current_index == -1:
		assert(false, "找不到当前武器UUID:%d 在备选列表中" % current_uuid)
		return uuid_list[0]
	var next_index = (current_index + 1) % uuid_list.size()
	return uuid_list[next_index]

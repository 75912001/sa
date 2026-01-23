# 调试工具
class_name GDebugClass
extends Node

# 全局开关
var enabled: bool = true


func print_player_record(record) -> void:
	if not enabled:
		return

	print("\n========== PlayerRecord 详细数据 ==========")
	print("UUID: %d  # 已使用的最大唯一ID" % record.get_UUID())

	var char_map = record.get_CharacterRecordMap()
	print("CharacterRecordMap: %d 个角色  # 角色记录表" % char_map.size())

	for char_uuid in char_map.keys():
		var char_record = char_map[char_uuid]
		print_character_record(char_record, 1)

	print("============================================\n")


func print_character_record(record, indent: int = 0) -> void:
	if not enabled:
		return

	var pre = _indent(indent)
	print("\n%s-------- CharacterRecord [UUID=%d] --------" % [pre, record.get_UUID()])
	print("%sUUID: %d  # 角色UUID" % [pre, record.get_UUID()])
	print("%sNick: \"%s\"  # 昵称" % [pre, record.get_Nick()])

	# RecordBaseMap 资产表
	var base_map = record.get_RecordBaseMap()
	print("%sRecordBaseMap: %d 项  # 资产表" % [pre, base_map.size()])
	for key in base_map.keys():
		var value = base_map[key]
		var key_name = _get_field_name(key)
		print("%s  [%d] %s = %d" % [pre, key, key_name, value])

	# RecordMap 记录表
	var record_map = record.get_RecordMap()
	if record_map.size() > 0:
		print("%sRecordMap: %d 项  # 记录表" % [pre, record_map.size()])
		for key in record_map.keys():
			var record_primary = record_map[key]
			print_record_primary(record_primary, indent + 2)

	# PetRecordMap 宠物记录表
	var pet_map = record.get_PetRecordMap()
	if pet_map.size() > 0:
		print("%sPetRecordMap: %d 项  # 宠物记录表" % [pre, pet_map.size()])
		for key in pet_map.keys():
			print("%s  [%d] PetRecord" % [pre, key])

	# WeaponRecordMap 武器记录表
	var weapon_map = record.get_WeaponRecordMap()
	if weapon_map.size() > 0:
		print("%sWeaponRecordMap: %d 项  # 武器记录表" % [pre, weapon_map.size()])
		for weapon_uuid in weapon_map.keys():
			var weapon_record = weapon_map[weapon_uuid]
			print_weapon_record(weapon_record, indent + 1)


func print_weapon_record(record, indent: int = 0) -> void:
	if not enabled:
		return

	var pre = _indent(indent)
	print("%s---- WeaponRecord [UUID=%d] ----" % [pre, record.get_UUID()])
	print("%s  UUID: %d" % [pre, record.get_UUID()])

	# RecordBaseMap
	var base_map = record.get_RecordBaseMap()
	print("%s  RecordBaseMap: %d 项" % [pre, base_map.size()])
	for key in base_map.keys():
		var value = base_map[key]
		var key_name = _get_field_name(key)
		print("%s    [%d] %s = %d" % [pre, key, key_name, value])

	# RecordMap
	var record_map = record.get_RecordMap()
	if record_map.size() > 0:
		print("%s  RecordMap: %d 项" % [pre, record_map.size()])
		for primary_key in record_map.keys():
			var record_primary = record_map[primary_key]
			print_record_primary(record_primary, indent + 2)


func print_record_primary(record, indent: int = 0) -> void:
	if not enabled:
		return

	var pre = _indent(indent)
	print("%s---- RecordPrimary [ID=%d] ----" % [pre, record.get_PrimaryID()])
	print("%s  PrimaryID: %d" % [pre, record.get_PrimaryID()])

	# RecordElementMap
	var element_map = record.get_RecordElementMap()
	if element_map.size() > 0:
		print("%s  RecordElementMap: %d 项" % [pre, element_map.size()])
		for secondary_key in element_map.keys():
			var record_secondary = element_map[secondary_key]
			print_record_secondary(record_secondary, indent + 2)


func print_record_secondary(record, indent: int = 0) -> void:
	if not enabled:
		return

	var pre = _indent(indent)
	print("%s---- RecordSecondary [ID=%d] ----" % [pre, record.get_SecondaryID()])
	print("%s  SecondaryID: %d" % [pre, record.get_SecondaryID()])
	print("%s  Timestamp: %d" % [pre, record.get_Timestamp()])
	print("%s  Data: %s" % [pre, str(record.get_Data())])
	print("%s  StrData: %s" % [pre, str(record.get_StrData())])


# 获取字段名称
func _get_field_name(key: int) -> String:
	match key:
		# AssetIDRecord 通用 [1,1000]
		PbAsset.AssetIDRecord.AssetIDRecord_Exp: return "经验值"
		PbAsset.AssetIDRecord.AssetIDRecord_HP: return "生命值"
		PbAsset.AssetIDRecord.AssetIDRecord_MP: return "魔法值"
		PbAsset.AssetIDRecord.AssetIDRecord_CreateTimestamp: return "创建时间戳"
		PbAsset.AssetIDRecord.AssetIDRecord_MapID: return "所在地图ID"
		PbAsset.AssetIDRecord.AssetIDRecord_X: return "位置X"
		PbAsset.AssetIDRecord.AssetIDRecord_Y: return "位置Y"
		PbAsset.AssetIDRecord.AssetIDRecord_Z: return "位置Z"
		PbAsset.AssetIDRecord.AssetIDRecord_Orientation: return "朝向"
		PbAsset.AssetIDRecord.AssetIDRecord_RebirthCount: return "转生次数"
		PbAsset.AssetIDRecord.AssetIDRecord_AssetID: return "资产ID"
		# CharacterAssetIDRecordBase 角色 [1001,2000]
		PbCharacter.CharacterAssetIDRecordBase.CharacterAssetIDRecordBase_Pose: return "姿势"
		PbCharacter.CharacterAssetIDRecordBase.CharacterAssetIDRecordBase_LastLoginTimestamp: return "上次登录时间戳"
		PbCharacter.CharacterAssetIDRecordBase.CharacterAssetIDRecordBase_LastLogoutTimestamp: return "上次登出时间戳"
		PbCharacter.CharacterAssetIDRecordBase.CharacterAssetIDRecordBase_AvailablePoint: return "可用点数"
		PbCharacter.CharacterAssetIDRecordBase.CharacterAssetIDRecordBase_AttributesStrength: return "腕力"
		PbCharacter.CharacterAssetIDRecordBase.CharacterAssetIDRecordBase_AttributesEndurance: return "耐力"
		PbCharacter.CharacterAssetIDRecordBase.CharacterAssetIDRecordBase_AttributesAgility: return "敏捷"
		PbCharacter.CharacterAssetIDRecordBase.CharacterAssetIDRecordBase_AttributesStamina: return "体力"
		# WeaponAssetIDRecordBase 武器 [10000,200000]
		PbWeapon.WeaponAssetIDRecordBase.WeaponAssetIDRecordBase_DamagePercent: return "伤害百分比"
		PbWeapon.WeaponAssetIDRecordBase.WeaponAssetIDRecordBase_CritRate: return "暴击概率"
		PbWeapon.WeaponAssetIDRecordBase.WeaponAssetIDRecordBase_CritDamageBonusRate: return "暴击伤害加成"
		_: return "未知字段"


# 缩进
func _indent(level: int) -> String:
	var result = ""
	for i in range(level):
		result += "  "
	return result

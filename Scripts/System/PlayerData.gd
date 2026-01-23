# 玩家数据-管理器
class_name PlayerDataMgr
extends Node


# 通过 UUID 获取武器记录
func get_weapon_record_by_uuid(weapon_uuid: int) -> PbWeapon.WeaponRecord:
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

# 保存-管理器
class_name SaveMgr
extends Node

#const _PbCharacter = preload("res://Scripts/Pb/Character.gd")

const SAVE_PATH = "res://Save/Player.save"

var player_record = null

func _ready() -> void:
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("Save"): # 目录不存在
		dir.make_dir("Save")

	player_record = PbCharacter.PlayerRecord.new()

	load_game()

func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH): # 有存档
		_load_from_file()
	else: # 无存档
		_create_new_save()

func _load_from_file() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file: # 打开存档-失败
		push_error("SaveMgr: 无法打开存档文件")
		return

	var bytes = file.get_buffer(file.get_length())

	var result = player_record.from_bytes(bytes)

	if result != PbCharacter.PB_ERR.NO_ERRORS:
		push_error("SaveMgr: 解析存档失败, 错误码: " + str(result))
		return

	print("SaveMgr: 存档加载成功")
	_init_systems_with_data()

func _create_new_save() -> void:
	print("SaveMgr: 未找到存档或解析失败，创建新存档...")

	var timestamp = int(Time.get_unix_time_from_system())

	# 初始化 UUID 管理器
	GUuidMgr.init_counter(0)

	var new_uuid = GUuidMgr.get_new_uuid()
	player_record.set_UUID(new_uuid)
	# 创建第一个默认角色
	var characterRecord = player_record.add_CharacterRecordMap(new_uuid)
	characterRecord.set_UUID(new_uuid)
	characterRecord.set_Nick("CharacterID-1000001")
	# 设置资产表
	characterRecord.add_RecordBaseMap(PbAsset.AssetIDRecord.AssetIDRecord_AssetID, 1000001)
	characterRecord.add_RecordBaseMap(PbAsset.AssetIDRecord.AssetIDRecord_Exp, 0)
	characterRecord.add_RecordBaseMap(PbAsset.AssetIDRecord.AssetIDRecord_CreateTimestamp, timestamp)
	characterRecord.add_RecordBaseMap(PbCharacter.CharacterAssetIDRecordBase.CharacterAssetIDRecordBase_LastLoginTimestamp, timestamp)
	characterRecord.add_RecordBaseMap(PbCharacter.CharacterAssetIDRecordBase.CharacterAssetIDRecordBase_AvailablePoint, 20)
	# 武器
	for weaponID in [11000001,11000002,11000003,11000004]:
		new_uuid = GUuidMgr.get_new_uuid()
		player_record.set_UUID(new_uuid)

		var weaponRecord = characterRecord.add_WeaponRecordMap(new_uuid)
		weaponRecord.set_UUID(new_uuid)
		weaponRecord.add_RecordBaseMap(PbAsset.AssetIDRecord.AssetIDRecord_AssetID, weaponID)
		weaponRecord.add_RecordBaseMap(PbAsset.AssetIDRecord.AssetIDRecord_Exp, 0)
		weaponRecord.add_RecordBaseMap(PbWeapon.WeaponAssetIDRecordBase.WeaponAssetIDRecordBase_DamagePercent, 10)
		weaponRecord.add_RecordBaseMap(PbWeapon.WeaponAssetIDRecordBase.WeaponAssetIDRecordBase_CritRate, 20)
		weaponRecord.add_RecordBaseMap(PbWeapon.WeaponAssetIDRecordBase.WeaponAssetIDRecordBase_CritDamageBonusRate, 30)

		var recordPrimary = weaponRecord.add_RecordMap(PbWeapon.WeaponRecordPrimary.WeaponRecordPrimary_Slot)
		recordPrimary.set_PrimaryID(PbWeapon.WeaponRecordPrimary.WeaponRecordPrimary_Slot)
		var recordSecondary = recordPrimary.add_RecordElementMap(PbWeapon.WeaponRecordSecondary.WeaponRecordSecondary_Slot_Data)
		recordSecondary.set_SecondaryID(PbWeapon.WeaponRecordSecondary.WeaponRecordSecondary_Slot_Data)
		recordSecondary.set_Timestamp(timestamp)
		# Data
		recordSecondary.add_Data(1)
		recordSecondary.add_Data(2)
		recordSecondary.add_Data(3)
		# StrData
		recordSecondary.add_StrData("str1")
		recordSecondary.add_StrData("str2")
		recordSecondary.add_StrData("str3")
	# 武器-装备

	save()

func _init_systems_with_data() -> void:
	# --- UUID ---
	GUuidMgr.init_counter(player_record.get_UUID())

	# --- 更新登录时间戳 ---
	var current_time = int(Time.get_unix_time_from_system())
	var character_map = player_record.get_CharacterRecordMap()
	for character_uuid in character_map.keys():
		var character_record = character_map[character_uuid]
		character_record.add_RecordBaseMap(
			PbCharacter.CharacterAssetIDRecordBase.CharacterAssetIDRecordBase_LastLoginTimestamp,
			current_time
		)
	save()

	GDebug.print_player_record(player_record)

func save() -> void:
	var bytes = player_record.to_bytes()
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_buffer(bytes)
	print("SaveMgr: 存档已保存至 ", SAVE_PATH, "大小:", bytes)

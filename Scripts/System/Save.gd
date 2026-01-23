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
	characterRecord.add_RecordBaseMap(PbAsset.AssetIDRecord.AssetIDRecord_CreateTimestamp, int(Time.get_unix_time_from_system()))
	characterRecord.add_RecordBaseMap(PbCharacter.CharacterAssetIDRecordBase.CharacterAssetIDRecordBase_LastLoginTimestamp, int(Time.get_unix_time_from_system()))
	characterRecord.add_RecordBaseMap(PbCharacter.CharacterAssetIDRecordBase.CharacterAssetIDRecordBase_AvailablePoint, 20)

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

	_debug_print_player_record()

func save() -> void:
	var bytes = player_record.to_bytes()
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_buffer(bytes)
	print("SaveMgr: 存档已保存至 ", SAVE_PATH, "大小:", bytes)

# 调试打印 PlayerRecord 详细数据
func _debug_print_player_record() -> void:
	print("\n========== PlayerRecord 详细数据 ==========")
	print("UUID: %d  # 已使用的最大唯一ID" % player_record.get_UUID())

	var char_map = player_record.get_CharacterRecordMap()
	print("CharacterRecordMap: %d 个角色  # 角色记录表" % char_map.size())

	for char_uuid in char_map.keys():
		var char_record = char_map[char_uuid]
		print("\n  -------- CharacterRecord [UUID=%d] --------" % char_uuid)
		print("  UUID: %d  # 角色UUID" % char_record.get_UUID())
		print("  Nick: \"%s\"  # 昵称" % char_record.get_Nick())

		# RecordBaseMap 资产表
		var base_map = char_record.get_RecordBaseMap()
		print("  RecordBaseMap: %d 项  # 资产表" % base_map.size())
		for key in base_map.keys():
			var value = base_map[key]
			var key_name = _get_record_base_key_name(key)
			print("    [%d] %s = %d" % [key, key_name, value])

		# RecordMap 记录表
		var record_map = char_record.get_RecordMap()
		if record_map.size() > 0:
			print("  RecordMap: %d 项  # 记录表" % record_map.size())
			for key in record_map.keys():
				print("    [%d] RecordPrimary" % key)

		# PetRecordMap 宠物记录表
		var pet_map = char_record.get_PetRecordMap()
		if pet_map.size() > 0:
			print("  PetRecordMap: %d 项  # 宠物记录表" % pet_map.size())
			for key in pet_map.keys():
				print("    [%d] PetRecord" % key)

	print("============================================\n")


# 获取 RecordBaseMap key 的名称
func _get_record_base_key_name(key: int) -> String:
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
		_: return "未知字段"

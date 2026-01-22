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

	player_record = PbCharacter.PlayerRecord.new()
	var result = player_record.from_bytes(bytes)

	if result != PbCharacter.PB_ERR.NO_ERRORS:
		push_error("SaveMgr: 解析存档失败, 错误码: " + str(result))
		return

	print("SaveMgr: 存档加载成功")
	_init_systems_with_data()

func _create_new_save() -> void:
	print("SaveMgr: 未找到存档或解析失败，创建新存档...")
	player_record = PbCharacter.PlayerRecord.new()

	# 初始化 UUID 管理器
	GUuidMgr.init_counter(0)

	# 创建第一个默认角色
	var new_uuid = GUuidMgr.get_new_uuid()
	var characterRecord = PbCharacter.CharacterRecord.new()
	characterRecord.set_UUID(new_uuid)
	characterRecord.set_CharacterID(1000001)
	characterRecord.set_Nick("CharacterID-1000001")

	# 设置资产表
	var asset_map = characterRecord.get_AssetIDRecordMap()
	asset_map[PbAsset.AssetIDRecord.AssetIDRecord_Exp] = 0
	asset_map[PbAsset.AssetIDRecord.AssetIDRecord_UUID] = new_uuid 

	# 添加
	player_record.get_CharacterRecordMap()[new_uuid] = characterRecord

	save()

func _init_systems_with_data() -> void:
	# --- UUID ---
	var uuid = 0
	var characterRecordMap = player_record.get_CharacterRecordMap()
	for characterUUID in characterRecordMap.keys():
		var characterRecord = characterRecordMap[characterUUID]
		var assetIDRecordMap = characterRecord.get_AssetIDRecordMap()
		var val = assetIDRecordMap[PbAsset.AssetIDRecord.AssetIDRecord_UUID]
		if uuid < val:
			uuid = val
	GUuidMgr.init_counter(uuid)
	
	print("SaveMgr: 系统初始化完成，UUID计数器已同步至: ", uuid)

func save() -> void:
	var bytes = player_record.to_bytes()
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_buffer(bytes)
	print("SaveMgr: 存档已保存至 ", SAVE_PATH, "大小:", bytes)

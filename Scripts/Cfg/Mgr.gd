# 配置-管理器
# 负责加载、校验、组装配置文件

extends Node

# --- 配置数据 ---
var cfg_weapon_mgr: CfgWeaponMgr
var cfg_character_mgr: CfgCharacterMgr
var cfg_armor_mgr: CfgArmorMgr
var cfg_map_mgr: CfgMapMgr
var cfg_npc_mgr: CfgNpcMgr
var cfg_enemy_group_mgr: CfgEnemyGroupMgr

func _ready() -> void:
	cfg_weapon_mgr = CfgWeaponMgr.new()
	cfg_character_mgr = CfgCharacterMgr.new()
	cfg_armor_mgr = CfgArmorMgr.new()
	cfg_map_mgr = CfgMapMgr.new()
	cfg_npc_mgr = CfgNpcMgr.new()
	cfg_enemy_group_mgr = CfgEnemyGroupMgr.new()
	_load_all_cfg()

# 加载所有配置
func _load_all_cfg() -> void:
	# --- 加载 ---
	cfg_weapon_mgr.load("res://Cfg/weapon.yaml")
	cfg_character_mgr.load("res://Cfg/character.yaml")
	cfg_armor_mgr.load("res://Cfg/armor.yaml")
	cfg_map_mgr.load("res://Cfg/map.yaml")
	cfg_npc_mgr.load("res://Cfg/npc.yaml")
	cfg_enemy_group_mgr.load("res://Cfg/enemy.groups.yaml")  # 必须在NPC之后加载
	# --- 检查 ---
	cfg_weapon_mgr.check()
	cfg_character_mgr.check()
	cfg_armor_mgr.check()
	cfg_map_mgr.check()
	cfg_npc_mgr.check()
	cfg_enemy_group_mgr.check()
	# --- 组装 ---
	cfg_weapon_mgr.assemble()
	cfg_character_mgr.assemble()
	cfg_armor_mgr.assemble()
	cfg_map_mgr.assemble()
	cfg_npc_mgr.assemble()
	cfg_enemy_group_mgr.assemble()

	prints("配置加载完成")

# 加载YAML文件 (使用miniyaml插件)
func load_yaml(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		assert(false, "配置文件不存在: %s" % path)

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		assert(false, "无法打开配置文件: %s, 错误: %s" % [path, error_string(FileAccess.get_open_error())])

	var content := file.get_as_text()
	file.close()

	var result = YAML.parse(content)
	if result.has_error():
		assert(false, "YAML解析失败: %s, 错误: %s" % [path, result.get_error()])

	var data = result.get_data()
	if data is Array and data.size() > 0:
		data = data[0]  # parse返回数组，取第一个文档

	if not data is Dictionary:
		assert("配置文件根节点必须是对象: %s" % path)

	return data

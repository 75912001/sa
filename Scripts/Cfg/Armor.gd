# 配置-护甲-管理器
class_name CfgArmorMgr

extends RefCounted

# --- 单个护甲数据 ---
class CfgArmorEntry extends RefCounted:
	var id: int
	var name: String
	var type: PbArmor.ArmorType
	var resPath: String
	var description: String
	func show() -> String:
		return name

# --- 缓存数据 ---
var armors: Dictionary = {}  # 护甲ID -> ArmorEntry

# 加载配置
func load(path: String) -> void:
	var data := GCfgMgr.load_yaml(path)
	var armors_array: Array = data.get("armors", [])
	for item in armors_array:
		var entry := CfgArmorEntry.new()
		entry.id = item.get("id", 0)
		assert(PbAsset.AssetIDRange.AssetIDRange_Armor_Start <= entry.id && entry.id <= PbAsset.AssetIDRange.AssetIDRange_Armor_End, "护甲ID-超出范围: %d" % entry.id)
		entry.name = item.get("name", "")
		assert(not entry.name.is_empty(), "护甲名称为空: ID:%d" % entry.id)
		entry.type = item.get("type", 0)
		assert(PbArmor.ArmorType.ArmorType_Unknow < entry.type and entry.type < PbArmor.ArmorType.ArmorType_Max,
			"护甲类型无效: ID:%d, type:%d" % [entry.id, entry.type])
		entry.resPath = item.get("resPath", "")
		assert(not entry.resPath.is_empty(), "护甲资源路径为空: ID:%d" % entry.id)
		entry.description = item.get("description", "")
		if armors.has(entry.id):
			assert(false, "护甲ID-重复: %d" % entry.id)
		else:
			armors[entry.id] = entry

# 校验配置
func check() -> void:
	return

# 组装配置 (预处理/索引构建)
func assemble() -> void:
	pass

# 获取护甲
func get_armor(id: int) -> CfgArmorEntry:
	return armors.get(id, null)

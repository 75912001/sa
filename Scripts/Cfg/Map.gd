# 配置-地图-管理器
class_name CfgMapMgr

extends RefCounted

# --- 单个地图数据 ---
class CfgMapEntry extends RefCounted:
	var id: int
	var name: String
	var res_path: String
	var bgm_path: String
	func show() -> String:
		return name

# --- 缓存数据 ---
var maps: Dictionary = {}  # 地图ID -> CfgMapEntry

# 加载配置
func load(path: String) -> void:
	var data := GCfgMgr.load_yaml(path)
	var maps_array: Array = data.get("maps", [])
	for item in maps_array:
		var entry := CfgMapEntry.new()
		entry.id = item.get("assetID", 0)
		assert(0 < entry.id, "地图ID无效: %d" % entry.id)
		assert(PbAsset.AssetIDRange.AssetIDRange_Map_Start <= entry.id && entry.id <= PbAsset.AssetIDRange.AssetIDRange_Map_End, "地图ID-超出范围: %d" % entry.id)
		entry.name = item.get("name", "")
		assert(not entry.name.is_empty(), "地图名称为空: ID:%d" % entry.id)
		entry.res_path = item.get("resPath", "")
		assert(not entry.res_path.is_empty(), "地图资源为空: ID:%d" % entry.id)
		entry.bgm_path = item.get("bgmPath", "")
		assert(not entry.bgm_path.is_empty(), "地图bgm为空: ID:%d" % entry.id)
		if maps.has(entry.id):
			assert(false, "地图ID-重复: %d" % entry.id)
		else:
			maps[entry.id] = entry

# 校验配置
func check() -> void:
	for map_id in maps:
		var entry: CfgMapEntry = maps[map_id]
		# prints("地图:", entry.show())

# 组装配置 (预处理/索引构建)
func assemble() -> void:
	pass

# 获取地图
func get_map(id: int) -> CfgMapEntry:
	return maps.get(id, null)

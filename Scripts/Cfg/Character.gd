# 配置-角色-管理器
class_name CfgCharacterMgr

extends RefCounted

# --- 单个角色数据 ---
class CfgCharacterEntry extends RefCounted:
	var id: int
	var name: String
	var speed: float
	var rotation_speed: float
	var roll_distance: int
	var roll_duration: int
	var skeletonPath: String
	var description: String
	func show() -> String:
		return name

# --- 缓存数据 ---
var characters: Dictionary = {}  # 角色ID -> CfgCharacterEntry

# 加载配置
func load(path: String) -> void:
	var data := GCfgMgr.load_yaml(path)
	var characters_array: Array = data.get("characters", [])
	for item in characters_array:
		var entry := CfgCharacterEntry.new()
		entry.id = item.get("id", 0)
		assert(PbAsset.AssetIDRange.AssetIDRange_Character_Start <= entry.id && entry.id <= PbAsset.AssetIDRange.AssetIDRange_Character_End,
			"角色ID-超出范围: %d" % entry.id)
		entry.name = item.get("name", "")
		assert(not entry.name.is_empty(), "角色名称为空: ID:%d" % entry.id)
		entry.speed = item.get("speed", 0.0)
		assert(0.0 < entry.speed, "角色速度非法: ID:%d" % entry.id)
		entry.rotation_speed = item.get("rotationSpeed", 0.0)
		assert(0.0 < entry.rotation_speed, "角色旋转速度非法: ID:%d" % entry.id)
		entry.roll_distance = item.get("rollDistance", 1800)
		entry.roll_duration = item.get("rollDuration", 1200)
		entry.skeletonPath = item.get("skeletonPath", "")
		assert(not entry.skeletonPath.is_empty(), "角色骨架路径为空: ID:%d" % entry.id)
		entry.description = item.get("description", "")
		if characters.has(entry.id):
			assert(false, "角色ID-重复: %d" % entry.id)
		else:
			characters[entry.id] = entry

# 校验配置
func check() -> void:
	for character_id in characters:
		var entry: CfgCharacterEntry = characters[character_id]
		# prints("角色:", entry.show())

# 组装配置 (预处理/索引构建)
func assemble() -> void:
	pass

# 获取角色
func get_character(id: int) -> CfgCharacterEntry:
	return characters.get(id, null)

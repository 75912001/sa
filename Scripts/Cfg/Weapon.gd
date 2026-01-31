# 配置-武器-管理器
class_name CfgWeaponMgr 

extends RefCounted

# --- 单个武器数据 ---
class CfgWeaponEntry extends RefCounted:
	var id: int
	var name: String
	var type: PbWeapon.WeaponType
	var attack: int
	var attack_duration_ms: int = 0  # 攻击动画时长(毫秒)
	var resPath: String
	var description: String
	func show() -> String:
		return name

# --- 缓存数据 ---
var weapons: Dictionary = {}  # 武器ID -> WeaponEntry

# 加载配置
func load(path: String) -> void:
	var data := GCfgMgr.load_yaml(path)
	var weapons_array: Array = data.get("weapons", [])
	for item in weapons_array:
		var entry := CfgWeaponEntry.new()
		entry.id = item.get("id", 0)
		assert(PbAsset.AssetIDRange.AssetIDRange_Weapon_Start <= entry.id && entry.id <= PbAsset.AssetIDRange.AssetIDRange_Weapon_End,
			"武器ID-超出范围: %d" % entry.id)
		entry.name = item.get("name", "")
		assert(not entry.name.is_empty(), "武器名称为空: ID:%d" % entry.id)
		entry.type = item.get("type", 0)
		assert(PbWeapon.WeaponType.WeaponType_ShortSword <= entry.type and entry.type < PbWeapon.WeaponType.WeaponType_Max,
			"武器类型无效: ID:%d, type:%d" % [entry.id, entry.type])
		entry.attack = item.get("attack", 0)
		assert(0 < entry.attack, "武器攻击力非法: ID:%d " % entry.id)
		entry.attack_duration_ms = item.get("attack_duration_ms", 0)
		entry.resPath = item.get("resPath", "")
		assert(not entry.resPath.is_empty(), "武器资源路径为空: ID:%d" % entry.id)
		entry.description = item.get("description", "")
		if weapons.has(entry.id):
			assert(false, "武器ID-重复: %d" % entry.id)
		else:
			weapons[entry.id] = entry

# 校验配置
func check() -> void:
	for weapon_id in weapons:
		var entry: CfgWeaponEntry = weapons[weapon_id]
		#prints("武器:", entry.show())

# 组装配置 (预处理/索引构建)
func assemble() -> void:
	pass

# 获取武器
func get_weapon(id: int) -> CfgWeaponEntry:
	return weapons.get(id, null)

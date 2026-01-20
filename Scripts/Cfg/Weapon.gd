class_name WeaponCfg extends RefCounted
## 武器配置数据

#const PbWeapon = preload("res://Scripts/Pb/Weapon.gd")

# --- 单个武器数据 ---
class WeaponEntry extends RefCounted:
	var id: int
	var name: String
	var type: PbWeapon.WeaponType
	var attack: int
	var description: String

# --- 缓存数据 ---
var weapons: Dictionary = {}  # 武器ID -> WeaponEntry

## 加载配置
func load(path: String) -> void:
	var data := CfgMgr.load_yaml(path)
	var weapons_array: Array = data.get("weapons", [])
	for item in weapons_array:
		var entry := WeaponEntry.new()
		entry.id = item.get("id", 0)
		if entry.id < PbAsset.AssetIDRange.AssetIDRange_Weapon_Start || PbAsset.AssetIDRange.AssetIDRange_Weapon_End < entry.id:
			assert(false, "武器ID-超出范围: %d" % entry.id)
		entry.name = item.get("name", "")
		entry.type = item.get("type", 0)
		entry.attack = item.get("attack", 0)
		entry.description = item.get("description", "")
		if weapons.has(entry.id):
			assert(false, "武器ID-重复: %d" % entry.id)
		else:
			weapons[entry.id] = entry

## 校验配置
func check() -> void:
	assert(not weapons.is_empty(), "weapons 不能为空")

	var seen_ids: Dictionary = {}
	for weapon_id in weapons:
		var w: WeaponEntry = weapons[weapon_id]

		# ID有效性
		assert(w.id > 0, "武器ID无效: %d" % w.id)

		# ID唯一性
		assert(not seen_ids.has(w.id), "武器ID重复: %d" % w.id)
		seen_ids[w.id] = true

		# 名称
		assert(not w.name.is_empty(), "武器名称为空: ID=%d" % w.id)

		# 类型有效性
		assert(w.type >= PbWeapon.WeaponType.WeaponType_Dagger and w.type < PbWeapon.WeaponType.WeaponType_Max,
			"武器类型无效: ID=%d, type=%d" % [w.id, w.type])

		# 攻击力
		assert(w.attack >= 0, "武器攻击力不能为负: ID=%d, attack=%d" % [w.id, w.attack])

## 组装配置 (预处理/索引构建)
func assemble() -> void:
	pass

## 获取武器
func get_weapon(id: int) -> WeaponEntry:
	return weapons.get(id, null)

## 获取所有武器ID
func get_all_weapon_ids() -> Array:
	return weapons.keys()

## 按类型获取武器
func get_weapons_by_type(type: PbWeapon.WeaponType) -> Array[WeaponEntry]:
	var result: Array[WeaponEntry] = []
	for weapon_id in weapons:
		var w: WeaponEntry = weapons[weapon_id]
		if w.type == type:
			result.append(w)
	return result

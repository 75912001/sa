class_name WeaponCfg extends RefCounted
## 武器配置数据

# --- 引用Pb定义的武器类型 ---
const PbWeapon = preload("res://Scripts/Pb/Weapon.gd")

# --- 单个武器数据 ---
class WeaponEntry extends RefCounted:
	var id: int
	var name: String
	var type: PbWeapon.WeaponType
	var attack: int
	var description: String

	func _to_string() -> String:
		return "Weapon(%d: %s)" % [id, name]

# --- 数据 ---
var weapons_type: Dictionary = {}  # 类型名 -> 类型ID
var weapons: Dictionary = {}       # 武器ID -> WeaponEntry

## 从字典加载
static func load_from_dict(data: Dictionary) -> WeaponCfg:
	var config := WeaponCfg.new()

	# 加载武器类型（过滤注释）
	var types: Dictionary = data.get("weaponsType", {})
	for key in types.keys():
		if not key.begins_with("_"):
			config.weapons_type[key] = types[key]

	# 加载武器列表
	var weapons_array: Array = data.get("weapons", [])
	for weapon_data in weapons_array:
		var entry := WeaponEntry.new()
		entry.id = weapon_data.get("id", 0)
		entry.name = weapon_data.get("name", "")
		entry.type = weapon_data.get("type", 0)
		entry.attack = weapon_data.get("attack", 0)
		entry.description = weapon_data.get("description", "")
		config.weapons[entry.id] = entry

	return config

## 检查合法性
func check() -> Array[String]:
	var errors: Array[String] = []

	# 检查武器类型
	if weapons_type.is_empty():
		errors.append("weaponsType 不能为空")

	# 检查武器列表
	if weapons.is_empty():
		errors.append("weapons 不能为空")

	# 检查每个武器
	var seen_ids: Dictionary = {}
	for weapon_id in weapons:
		var weapon: WeaponEntry = weapons[weapon_id]

		# ID有效性
		if weapon.id <= 0:
			errors.append("武器ID无效: %d" % weapon.id)

		# ID唯一性
		if seen_ids.has(weapon.id):
			errors.append("武器ID重复: %d" % weapon.id)
		seen_ids[weapon.id] = true

		# 名称
		if weapon.name.is_empty():
			errors.append("武器名称为空: ID=%d" % weapon.id)

		# 类型有效性
		if weapon.type < PbWeapon.WeaponType.WeaponType_Dagger or weapon.type >= PbWeapon.WeaponType.WeaponType_Max:
			errors.append("武器类型无效: ID=%d, type=%d" % [weapon.id, weapon.type])

		# 攻击力
		if weapon.attack < 0:
			errors.append("武器攻击力不能为负: ID=%d, attack=%d" % [weapon.id, weapon.attack])

	return errors

func assemble()->void:
	return

## 获取武器
func get_weapon(id: int) -> WeaponEntry:
	return weapons.get(id, null)

## 获取所有武器ID
func get_all_weapon_ids() -> Array:
	return weapons.keys()

## 按类型获取武器
func get_weapons_by_type(type: int) -> Array[WeaponEntry]:
	var result: Array[WeaponEntry] = []
	for weapon_id in weapons:
		var weapon: WeaponEntry = weapons[weapon_id]
		if weapon.type == type:
			result.append(weapon)
	return result

## 获取类型ID
func get_type_id(type_name: String) -> int:
	return weapons_type.get(type_name, 0)

class_name CfgAsset extends RefCounted
## 资产配置数据

# --- ID范围 ---
var record_start: int
var record_end: int
var character_start: int
var character_end: int
var map_start: int
var map_end: int
var weapon_start: int
var weapon_end: int

# --- 记录字段映射 (字段名 -> ID) ---
var record_fields: Dictionary = {}

## 从字典加载
static func load_cfg(data: Dictionary) -> CfgAsset:
	var cfg := CfgAsset.new()

	# 加载ID范围
	var id_range: Dictionary = data.get("idRange", {})
	cfg.record_start = id_range.get("recordStart", 0)
	cfg.record_end = id_range.get("recordEnd", 0)
	cfg.character_start = id_range.get("characterStart", 0)
	cfg.character_end = id_range.get("characterEnd", 0)
	cfg.map_start = id_range.get("mapStart", 0)
	cfg.map_end = id_range.get("mapEnd", 0)
	cfg.weapon_start = id_range.get("weaponStart", 0)
	cfg.weapon_end = id_range.get("weaponEnd", 0)

	# 加载记录字段（过滤掉注释字段）
	var record: Dictionary = data.get("record", {})
	for key in record.keys():
		if not key.begins_with("_"):
			cfg.record_fields[key] = record[key]

	return cfg

## 检查合法性
func check_cfg() -> Array[String]:
	var errors: Array[String] = []

	# 检查ID范围有效性
	if record_start <= 0:
		errors.append("record_start 必须大于0")
	if record_end <= record_start:
		errors.append("record_end 必须大于 record_start")

	if character_start <= record_end:
		errors.append("character_start 必须大于 record_end")
	if character_end <= character_start:
		errors.append("character_end 必须大于 character_start")

	if map_start <= character_end:
		errors.append("map_start 必须大于 character_end")
	if map_end <= map_start:
		errors.append("map_end 必须大于 map_start")

	if weapon_start <= map_end:
		errors.append("weapon_start 必须大于 map_end")
	if weapon_end <= weapon_start:
		errors.append("weapon_end 必须大于 weapon_start")

	# 检查记录字段
	if record_fields.is_empty():
		errors.append("record_fields 不能为空")

	# 检查字段ID唯一性
	var seen_ids: Dictionary = {}
	for field_name in record_fields:
		var field_id: int = record_fields[field_name]
		if seen_ids.has(field_id):
			errors.append("记录字段ID重复: %s 和 %s 都使用 ID %d" % [seen_ids[field_id], field_name, field_id])
		else:
			seen_ids[field_id] = field_name

	return errors

func assemble_cfg() -> void:
	return 

## 获取记录字段ID
func get_record_field_id(field_name: String) -> int:
	var id = record_fields.get(field_name, -1)
	if id == -1:
		assert(false, "未知的记录字段: %s" % field_name)
	return id

## 检查ID是否在记录范围内
func is_record_id(id: int) -> bool:
	return id >= record_start and id <= record_end

## 检查ID是否在角色范围内
func is_character_id(id: int) -> bool:
	return id >= character_start and id <= character_end

## 检查ID是否在地图范围内
func is_map_id(id: int) -> bool:
	return id >= map_start and id <= map_end

## 检查ID是否在武器范围内
func is_weapon_id(id: int) -> bool:
	return id >= weapon_start and id <= weapon_end

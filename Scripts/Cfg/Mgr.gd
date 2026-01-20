extends Node
## 配置管理器 (Autoload)
## 负责加载、校验、组装配置文件

# --- 配置路径 ---
const ASSET_CONFIG_PATH := "res://config/asset.json"
const WEAPON_CONFIG_PATH := "res://config/weapon.json"

# --- 配置数据 ---
var asset: AssetConfig
var weapon: WeaponConfig

# --- 加载状态 ---
var _is_loaded := false
var _load_errors: Array[String] = []

func _ready() -> void:
	_load_all_configs()

## 加载所有配置
func _load_all_configs() -> void:
	_load_errors.clear()

	# 1. Load - 加载
	var asset_data := _load_json(ASSET_CONFIG_PATH)
	var weapon_data := _load_json(WEAPON_CONFIG_PATH)

	if asset_data.is_empty() or weapon_data.is_empty():
		_handle_load_failure()
		return

	# 2. Assemble - 组装
	asset = AssetConfig.load_from_dict(asset_data)
	weapon = WeaponConfig.load_from_dict(weapon_data)

	# 3. Check - 校验
	var asset_errors := asset.check()
	var weapon_errors := weapon.check()

	_load_errors.append_array(asset_errors)
	_load_errors.append_array(weapon_errors)

	# 跨配置校验
	_check_cross_config()

	if not _load_errors.is_empty():
		_handle_check_failure()
		return

	_is_loaded = true
	prints("[ConfigMgr] 配置加载成功")
	prints("  - 资产ID范围: record[%d-%d] character[%d-%d] map[%d-%d] weapon[%d-%d]" % [
		asset.record_start, asset.record_end,
		asset.character_start, asset.character_end,
		asset.map_start, asset.map_end,
		asset.weapon_start, asset.weapon_end
	])
	prints("  - 记录字段: %d 个" % asset.record_fields.size())
	prints("  - 武器类型: %d 种" % weapon.weapons_type.size())
	prints("  - 武器数量: %d 个" % weapon.weapons.size())

## 加载JSON文件
func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_load_errors.append("配置文件不存在: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_load_errors.append("无法打开配置文件: %s, 错误: %s" % [path, error_string(FileAccess.get_open_error())])
		return {}

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(content)
	if parse_result != OK:
		_load_errors.append("JSON解析失败: %s, 行 %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}

	var data = json.data
	if not data is Dictionary:
		_load_errors.append("配置文件根节点必须是对象: %s" % path)
		return {}

	return data

## 跨配置校验
func _check_cross_config() -> void:
	# 可在此添加跨配置的校验逻辑
	# 例如: 武器ID是否在asset定义的武器范围内
	pass

## 处理加载失败
func _handle_load_failure() -> void:
	push_error("[ConfigMgr] 配置加载失败:")
	for err in _load_errors:
		push_error("  - %s" % err)
	# 在开发阶段，可以选择退出游戏
	# get_tree().quit(1)

## 处理校验失败
func _handle_check_failure() -> void:
	push_error("[ConfigMgr] 配置校验失败:")
	for err in _load_errors:
		push_error("  - %s" % err)
	# 在开发阶段，可以选择退出游戏
	# get_tree().quit(1)

## 是否加载成功
func is_loaded() -> bool:
	return _is_loaded

## 获取加载错误
func get_errors() -> Array[String]:
	return _load_errors

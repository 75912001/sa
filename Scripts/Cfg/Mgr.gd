extends Node
## 配置管理器 (Autoload)
## 负责加载、校验、组装配置文件

# --- 配置数据 ---
var weapon: WeaponCfg

func _ready() -> void:
	weapon = WeaponCfg.new()
	_load_all_cfg()

## 加载所有配置
func _load_all_cfg() -> void:
	# --- 加载 ---
	weapon.load("res://Cfg/weapon.yaml")
	# --- 检查 ---
	weapon.check()
	# --- 组装 ---
	weapon.assemble()
	
	prints("配置加载完成")

## 加载YAML文件 (使用miniyaml插件)
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

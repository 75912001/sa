# UUID-管理器
class_name UuidMgr
extends Node

# UUID 计数器
var _current_uuid: int = 0

# 初始化计数器 (通常在加载存档后调用，传入已存在的最大 UUID)
func init_counter(max_exist_uuid: int) -> void:
	_current_uuid = max_exist_uuid
	print("UuidMgr 初始化，当前最大ID: ", _current_uuid)

# 获取一个新的 UUID，并自增
func get_new_uuid() -> int:
	_current_uuid += 1
	return _current_uuid

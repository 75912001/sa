class_name World
# 游戏世界管理器
extends Node3D

# 地图ID (关联 map.yaml)
@export var map_id: int = 2000001

# 引用刚才创建的空容器
@onready var _map_loader: Node3D = $MapLoader

func _ready() -> void:
	load_map(map_id)

# 动态加载地图
func load_map(map_id: int) -> void:
	# 查找配置
	var map_config = GCfgMgr.cfg_map_mgr.get_map(map_id)
	assert(map_config != null, "World: 未找到地图配置 ID: %d" % map_id)

	# 清理当前地图
	for child in _map_loader.get_children():
		child.queue_free()

	# 动态加载场景文件
	var map_path = map_config.res_path

	if not ResourceLoader.exists(map_path):
		assert(false, "World: 地图文件不存在: %s" % map_path)

	var map_scene = load(map_path)
	var map_instance = map_scene.instantiate()
	
	# 放入容器
	_map_loader.add_child(map_instance)
	print("World: 已加载地图 [%s]" % map_config.name)
	
	# 设置玩家位置
	if GGameMgr.player:
		var spawn_point = map_instance.find_child("SpawnPoint")
		if spawn_point:
			GGameMgr.player.global_position = spawn_point.global_position
			# 如果出生点有旋转信息，也可以同步
			GGameMgr.player.global_rotation.y = spawn_point.global_rotation.y
		else:
			GGameMgr.player.global_position = Vector3(0, 0, 0)
	else:
		push_error("World: GGameMgr.player 为空，无法设置玩家位置")

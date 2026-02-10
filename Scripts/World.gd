class_name World
# 游戏世界管理器
extends Node3D

# 地图ID (关联 map.yaml)
@export var map_id: int = 2000001

# 引用刚才创建的空容器
@onready var _map_loader: Node3D = $MapLoader

# NPC管理器
var npc_mgr: NPCMgr

func _ready() -> void:
	load_map(map_id)

# 动态加载地图
func load_map(_map_id: int) -> void:
	# 查找配置
	var map_config = GCfgMgr.cfg_map_mgr.get_map(_map_id)
	assert(map_config != null, "World: 未找到地图配置 ID: %d" % _map_id)

	# 清理当前地图
	for child in _map_loader.get_children():
		child.queue_free()

	# 动态加载场景文件
	var map_path = map_config.res_path

	assert(ResourceLoader.exists(map_path), "World: 地图文件不存在: %s" % map_path)

	var map_scene = load(map_path)
	var map_instance = map_scene.instantiate()
	
	# 放入容器
	_map_loader.add_child(map_instance)
	print("World: 已加载地图 [%s]" % map_config.name)

	# 设置玩家位置
	GGameMgr.player.global_position = Vector3(0, 0, 0)

	# 清理-旧
	if npc_mgr:
		npc_mgr.clear_all_npcs()
	# 初始化NPC管理器
	npc_mgr = NPCMgr.new()
	npc_mgr.setup(_map_loader)  # 使用地图容器作为NPC父节点

	# 根据地图配置生成NPC
	npc_mgr.spawn_npcs_from_config(map_config)

extends Node3D
# 相机-跟随

# --- 配置 ---
@export_group("Map Settings")
# 拖入地图的 MeshInstance3D，脚本会自动计算多大
@export var map_mesh: MeshInstance3D 
# 视野边距：为了防止看到地图外的虚空，必须往里缩一点 (通常等于 Camera Size 的一半左右)
@export var view_margin: float = 18.0 
@export_group("Smooth Settings")
@export var smooth_speed: float = 10.0

# --- 变量 ---
var _limit_left: float = -1000.0
var _limit_right: float = 1000.0
var _limit_top: float = -1000.0
var _limit_bottom: float = 1000.0

func _ready() -> void:
	if map_mesh: # 绑定了地图网格
		_calculate_map_limits()

func _process(delta: float) -> void:
	# 【核心】钳制坐标 (Clamp)
	# 如果目标坐标超出了 limit 范围，就强制设为 limit 值
	var final_x = clamp(GGameMgr.player.global_position.x, _limit_left, _limit_right)
	var final_z = clamp(GGameMgr.player.global_position.z, _limit_top, _limit_bottom)
	
	# 构造目标位置 (Y轴保持不变，只动水平面)
	var desired_pos = Vector3(final_x, global_position.y, final_z)
	
	# 平滑移动
	global_position = global_position.lerp(desired_pos, smooth_speed * delta)

func _calculate_map_limits():
	# 获取网格的包围盒 (AABB)
	var aabb = map_mesh.mesh.get_aabb()
	var scaled_size = aabb.size
	var scaled_start = aabb.position
	
	var global_pos = map_mesh.global_position
	# 计算绝对边缘
	var edge_left = global_pos.x + scaled_start.x
	var edge_right = global_pos.x + scaled_start.x + scaled_size.x
	var edge_top = global_pos.z + scaled_start.z
	var edge_bottom = global_pos.z + scaled_start.z + scaled_size.z
	# 应用边距
	_limit_left = edge_left + view_margin
	_limit_right = edge_right - view_margin
	_limit_top = edge_top + view_margin
	_limit_bottom = edge_bottom - view_margin

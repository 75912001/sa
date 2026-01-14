extends Node3D

# --- 配置区 ---
@export_group("Map Settings")
# 拖入地图的 MeshInstance3D，脚本会自动计算多大
@export var map_mesh: MeshInstance3D 
# 视野边距：为了防止看到地图外的虚空，必须往里缩一点 (通常等于 Camera Size 的一半左右)
@export var view_margin: float = 18.0 

@export_group("Smooth Settings")
@export var smooth_speed: float = 10.0

# --- 内部变量 ---
var target: Node3D
var limit_left: float = -1000.0
var limit_right: float = 1000.0
var limit_top: float = -1000.0
var limit_bottom: float = 1000.0

func _ready() -> void:
	# 1. 自动寻找主角 (这就是为什么要加 group 的原因)
	var players = get_tree().get_nodes_in_group("Player")
	if 0 < players.size():
		target = players[0]
	
	# 2. 如果绑定了地图网格，计算边界
	if map_mesh:
		calculate_map_limits()

func calculate_map_limits():
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
	limit_left = edge_left + view_margin
	limit_right = edge_right - view_margin
	limit_top = edge_top + view_margin
	limit_bottom = edge_bottom - view_margin

func _process(delta: float) -> void:
	if not target:
		return

	# 1. 获取目标当前位置
	var target_pos = target.global_position
	
	# 2. 【核心】钳制坐标 (Clamp)
	# 如果目标坐标超出了 limit 范围，就强制设为 limit 值
	var final_x = clamp(target_pos.x, limit_left, limit_right)
	var final_z = clamp(target_pos.z, limit_top, limit_bottom)
	
	# 3. 构造目标位置 (Y轴保持不变，只动水平面)
	var desired_pos = Vector3(final_x, global_position.y, final_z)
	
	# 4. 平滑移动
	global_position = global_position.lerp(desired_pos, smooth_speed * delta)

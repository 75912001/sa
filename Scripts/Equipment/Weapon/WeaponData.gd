class_name WeaponData extends Resource
## 武器配置数据

# --- 配置 ---
@export var weapon_id: int              # 武器id
@export_file("*.tscn") var scene_path: String  # 武器场景路径
@export_file("*.gltf", "*.glb") var model_path: String  # 模型文件路径
@export var grip_position: Vector3           # 握持位置偏移
@export var grip_rotation_degrees: Vector3   # 握持旋转（欧拉角，度数）
@export var grip_scale: Vector3 = Vector3.ONE  # 握持缩放

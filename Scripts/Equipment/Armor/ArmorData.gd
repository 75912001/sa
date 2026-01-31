class_name ArmorData extends Resource

@export var armor_id: int
@export_file("*.tscn") var scene_path: String

@export var offset_position: Vector3           # 位置偏移
@export var offset_rotation_degrees: Vector3   # 旋转（欧拉角，度数）
@export var offset_scale: Vector3 = Vector3.ONE  # 缩放

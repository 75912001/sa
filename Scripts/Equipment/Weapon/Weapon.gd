# 通用武器. 
# 不同武器, sword, axe ... 共用本脚本
class_name Weapon

extends Node3D

# --- 配置 ---
@export var weapon_data: WeaponData

func _ready() -> void:
	_apply_config()

func _process(delta: float) -> void:
	pass

## 应用武器配置
func _apply_config() -> void:
	# 加载模型
	var model_scene: PackedScene = load(weapon_data.model_path)
	assert(model_scene, "无法加载武器模型: %s" % weapon_data.model_path)

	var model_instance = model_scene.instantiate()
	$Grip/Model.add_child(model_instance)

	# 应用握持变换
	$Grip.position = weapon_data.grip_position
	$Grip.rotation_degrees = weapon_data.grip_rotation_degrees
	$Grip.scale = weapon_data.grip_scale

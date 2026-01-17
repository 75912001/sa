extends Node3D

# 通用武器. 
# 不同武器, sword, axe ... 共用本脚本
class_name Weapon

# --- 配置 ---
@export var weapon_data: WeaponData
@onready var _grip: Node3D = $Grip
@onready var _model_container: Node3D = $Grip/Model

func _ready() -> void:
	if weapon_data:
		_apply_config()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

## 应用武器配置
func _apply_config() -> void:
	# 加载模型
	var model_scene: PackedScene = load(weapon_data.model_path)
	if not model_scene:
		push_error("无法加载武器模型: " + weapon_data.model_path)
		return

	var model_instance = model_scene.instantiate()
	_model_container.add_child(model_instance)

	# 应用握持变换
	_grip.position = weapon_data.grip_position
	_grip.rotation_degrees = weapon_data.grip_rotation_degrees
	_grip.scale = weapon_data.grip_scale

## 获取武器名称
func get_weapon_name() -> String:
	return weapon_data.weapon_name if weapon_data else ""

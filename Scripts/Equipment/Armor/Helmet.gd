class_name Helmet
extends Node3D

# --- 头盔通用逻辑 (Helmet Generic Logic) ---
# 所有具体的头盔（如 Helmet.001）都应该继承自这个脚本

@export_group("References")
# 预留给子类/具体场景的节点引用
@export var model_root: Node3D

func _ready() -> void:
	assert(model_root != null, "[配置错误] 场景 '%s' 的 model_root 未赋值！请在编辑器中指定" % name)

# 虚函数
func on_equip() -> void:
	# 可以在这里处理头盔特有的逻辑，比如隐藏角色的头发
	print("Helmet: on_equip - %s" % name)

func on_unequip() -> void:
	# 恢复头发显示等
	print("Helmet: on_unequip - %s" % name)

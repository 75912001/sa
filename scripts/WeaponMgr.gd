extends Node

class_name WeaponMgr

@export var weapon_attachment_path: NodePath  # 这行让属性显示在检查器中

var weapon_attachment: BoneAttachment3D
var current_weapon: Node3D = null

func _ready() -> void:
	weapon_attachment = get_node(weapon_attachment_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

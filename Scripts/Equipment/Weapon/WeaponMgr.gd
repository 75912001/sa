# 武器-管理器
class_name WeaponMgr
extends Node

# --- 配置 ---
@export var weapon_attachment_path: NodePath

# --- 信号 ---
signal weapon_equipped(weapon_uuid: int)
signal weapon_unequipped

# --- 变量 ---
var _weapon_attachment: BoneAttachment3D
var _current_weapon: Weapon = null
var _current_weapon_uuid: int = 0  # 0 表示无武器

func _ready() -> void:
	_weapon_attachment = get_node(weapon_attachment_path)

## 通过 UUID 装备武器
func equip_weapon_by_uuid(weapon_uuid: int) -> void:
	if weapon_uuid == 0:
		unequip_weapon()
		return

	if _current_weapon:
		unequip_weapon()

	var cfg = GPlayerData.get_weapon_cfg_by_uuid(weapon_uuid)
	var res_data = load(cfg.resPath) as WeaponData
	var scene = load(res_data.scene_path)
	if not scene:
		push_error("WeaponMgr: Failed to load scene: " + res_data.scene_path)
		return

	var weapon_instance: Weapon = scene.instantiate()
	weapon_instance.weapon_data = res_data
	_weapon_attachment.add_child(weapon_instance)

	_current_weapon = weapon_instance
	_current_weapon_uuid = weapon_uuid
	weapon_equipped.emit(weapon_uuid)

## 卸下当前武器
func unequip_weapon() -> void:
	if _current_weapon:
		_current_weapon.queue_free()
		_current_weapon = null
		_current_weapon_uuid = 0
		weapon_unequipped.emit()

## 获取当前武器 UUID
func get_current_weapon_uuid() -> int:
	return _current_weapon_uuid

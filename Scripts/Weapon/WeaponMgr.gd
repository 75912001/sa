extends Node
# 武器-管理器
class_name WeaponMgr

# --- 配置 ---
@export var weapon_attachment_path: NodePath

# --- 信号 ---
signal weapon_equipped(weapon_uuid: int)
signal weapon_unequipped

# --- 武器配置（AssetID -> 配置资源） ---
var _weapon_configs := {
	11000001: preload("res://Assets/Equipment/Weapon/Sword.001/data.tres"),
	11000002: preload("res://Assets/Equipment/Weapon/Sword.002/data.tres"),
	11000003: preload("res://Assets/Equipment/Weapon/Sword.003/data.tres"),
	11000004: preload("res://Assets/Equipment/Weapon/Sword.004/data.tres")
}

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

	# 获取 AssetID
	var asset_id = GPlayerData.get_weapon_asset_id_by_uuid(weapon_uuid)
	if asset_id == 0:
		push_warning("无法获取武器 AssetID, UUID: %d" % weapon_uuid)
		return

	if not _weapon_configs.has(asset_id):
		push_warning("武器配置不存在, AssetID: %d" % asset_id)
		return

	if _current_weapon:
		unequip_weapon()

	var config: WeaponData = _weapon_configs[asset_id]

	# 从配置加载对应的武器场景
	var weapon_scene: PackedScene = load(config.scene_path)
	if not weapon_scene:
		push_error("无法加载武器场景: " + config.scene_path)
		return

	var weapon_instance: Weapon = weapon_scene.instantiate()
	weapon_instance.weapon_data = config
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

## 是否持有武器
func has_weapon() -> bool:
	return _current_weapon != null

## 获取当前武器 UUID
func get_current_weapon_uuid() -> int:
	return _current_weapon_uuid

## 检查 AssetID 是否有武器配置
func has_asset_config(asset_id: int) -> bool:
	return _weapon_configs.has(asset_id)

extends Node
# 武器-管理器
class_name WeaponMgr

# --- 配置 ---
@export var weapon_attachment_path: NodePath

# --- 信号 ---
signal weapon_equipped(weapon_name: String)
signal weapon_unequipped

# --- 武器配置（槽位 -> 配置资源） ---
var _weapon_configs := {
	1: preload("res://Assets/Equipment/Weapon/Sword.001/data.tres"),
	2: preload("res://Assets/Equipment/Weapon/Sword.002/data.tres"),
	3: preload("res://Assets/Equipment/Weapon/Sword.003/data.tres"),
	4: preload("res://Assets/Equipment/Weapon/Sword.004/data.tres")
}

# --- 变量 ---
var _weapon_attachment: BoneAttachment3D
var _current_weapon: Weapon = null
var _current_slot: int = 0  # 0 表示无武器
var _input_cooldown := false

func _ready() -> void:
	_weapon_attachment = get_node(weapon_attachment_path)

## 装备指定槽位的武器
func equip_weapon(slot: int) -> void:
	if not _weapon_configs.has(slot):
		push_warning("武器槽位不存在: %d" % slot)
		return

	if _current_weapon:
		unequip_weapon()

	var config: WeaponData = _weapon_configs[slot]

	# 从配置加载对应的武器场景
	var weapon_scene: PackedScene = load(config.scene_path)
	if not weapon_scene:
		push_error("无法加载武器场景: " + config.scene_path)
		return

	var weapon_instance: Weapon = weapon_scene.instantiate()
	weapon_instance.weapon_data = config
	_weapon_attachment.add_child(weapon_instance)

	_current_weapon = weapon_instance
	_current_slot = slot
	weapon_equipped.emit(config.weapon_name)

## 卸下当前武器
func unequip_weapon() -> void:
	if _current_weapon:
		_current_weapon.queue_free()
		_current_weapon = null
		_current_slot = 0
		weapon_unequipped.emit()

## 是否持有武器
func has_weapon() -> bool:
	return _current_weapon != null

## 获取当前武器槽位
func get_current_slot() -> int:
	return _current_slot

## 处理输入
func handle_input() -> void:
	if _input_cooldown:
		return

	# Alt + 数字键
	if Input.is_key_pressed(KEY_ALT):
		var slot := _get_number_key_pressed()
		if 0 <= slot:
			_handle_slot_input(slot)

## 检测按下的数字键，返回 0-9，未按下返回 -1
func _get_number_key_pressed() -> int:
	if Input.is_key_pressed(KEY_0): return 0
	if Input.is_key_pressed(KEY_1): return 1
	if Input.is_key_pressed(KEY_2): return 2
	if Input.is_key_pressed(KEY_3): return 3
	if Input.is_key_pressed(KEY_4): return 4
	if Input.is_key_pressed(KEY_5): return 5
	if Input.is_key_pressed(KEY_6): return 6
	if Input.is_key_pressed(KEY_7): return 7
	if Input.is_key_pressed(KEY_8): return 8
	if Input.is_key_pressed(KEY_9): return 9
	return -1

## 处理槽位输入
func _handle_slot_input(slot: int) -> void:
	_start_cooldown()

	if slot == 0:
		unequip_weapon()
	elif slot == _current_slot:
		# 按同一槽位，卸下武器
		unequip_weapon()
	else:
		equip_weapon(slot)

## 开始输入冷却
func _start_cooldown() -> void:
	_input_cooldown = true
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(self):
		_input_cooldown = false

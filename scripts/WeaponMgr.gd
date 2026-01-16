extends Node
# 武器-管理器
class_name WeaponMgr

# --- 配置区 ---
@export var weapon_attachment_path: NodePath

var _Weapon_Name: String = "sword.001"
signal weapon_equipped(weapon_name: String)
signal weapon_unequipped

var _weapon_attachment: BoneAttachment3D
var _current_weapon: Node3D = null
var _current_weapon_name: String = ""  # 当前武器名称

# 武器切换按键冷却，防止连续触发 false: 不在cd中 true: 处于cd中
var _weapon_toggle_cooldown := false

# 预加载武器场景
var _weapon_scenes := {
	_Weapon_Name: preload("res://Scenes/Weapons/Sword.tscn")
}

func _ready() -> void:
	_weapon_attachment = get_node(weapon_attachment_path)
	if _weapon_attachment and 0 < _weapon_attachment.get_child_count(): # 有武器
		_current_weapon = _weapon_attachment.get_child(0)
		prints("current weapon:", _current_weapon)

func equip_weapon(weapon_name: String) -> void:
	if _current_weapon: # 已有武器
		unequip_weapon()

	if not _weapon_scenes.has(weapon_name): # 武器不存在
		push_warning("武器不存在: " + weapon_name)
		return

	# 实例化武器
	_current_weapon = _weapon_scenes[weapon_name].instantiate()
	_weapon_attachment.add_child(_current_weapon)
	_current_weapon_name = weapon_name

	weapon_equipped.emit(weapon_name)

func unequip_weapon() -> void:
	if _current_weapon:
		_current_weapon.queue_free()
		_current_weapon = null
		_current_weapon_name = ""
		weapon_unequipped.emit()

func has_weapon() -> bool:
	return _current_weapon != null

func toggle_weapon(weapon_name: String) -> void:
	if _current_weapon_name == weapon_name: # 相同
		unequip_weapon()
	else: # 不同
		equip_weapon(weapon_name)

func handle_input() -> void:
	# E 键切换武器
	if Input.is_key_pressed(KEY_E) and not _weapon_toggle_cooldown:
		_weapon_toggle_cooldown = true
		toggle_weapon(_Weapon_Name)
		# 冷却时间，防止连续触发
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(self):
			_weapon_toggle_cooldown = false

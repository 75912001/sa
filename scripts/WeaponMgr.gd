extends Node
# 武器-管理器
class_name WeaponMgr

signal weapon_equipped(weapon_name: String)
signal weapon_unequipped

@export var weapon_attachment_path: NodePath

var weapon_attachment: BoneAttachment3D
var current_weapon: Node3D = null
var current_weapon_name: String = ""  # 当前武器名称

# 武器切换按键冷却，防止连续触发
var weapon_toggle_cooldown := false

# 预加载武器场景
var weapon_scenes := {
	"sword.001": preload("res://Scenes/Weapons/Sword.tscn")
}

func _ready() -> void:
	weapon_attachment = get_node(weapon_attachment_path)
	# 检查是否已有武器（编辑器中放置的）
	if weapon_attachment and weapon_attachment.get_child_count() > 0:
		current_weapon = weapon_attachment.get_child(0)
		prints("current weapon:", current_weapon)

func equip_weapon(weapon_name: String) -> void:
	# 已有武器则先卸下
	if current_weapon:
		unequip_weapon()

	# 检查武器是否存在
	if not weapon_scenes.has(weapon_name):
		push_warning("武器不存在: " + weapon_name)
		return

	# 实例化武器
	current_weapon = weapon_scenes[weapon_name].instantiate()
	weapon_attachment.add_child(current_weapon)
	current_weapon_name = weapon_name

	weapon_equipped.emit(weapon_name)

func unequip_weapon() -> void:
	if current_weapon:
		current_weapon.queue_free()
		current_weapon = null
		current_weapon_name = ""
		weapon_unequipped.emit()

func has_weapon() -> bool:
	return current_weapon != null

func toggle_weapon(weapon_name: String) -> void:
	if current_weapon_name == weapon_name:
		# 相同武器，卸下
		unequip_weapon()
	else:
		# 不同武器，切换（equip_weapon 内部会先卸下旧武器）
		equip_weapon(weapon_name)


func handle_input() -> void:
	# E 键切换武器
	if Input.is_key_pressed(KEY_E) and not weapon_toggle_cooldown:
		weapon_toggle_cooldown = true
		toggle_weapon("sword.001")
		# 冷却时间，防止连续触发
		await get_tree().create_timer(0.3).timeout
		weapon_toggle_cooldown = false

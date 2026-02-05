class_name ArmorMgr extends Node

# --- 信号 ---
signal armor_equipped(armor_uuid: int)
signal armor_unequipped(armor_type: PbArmor.ArmorType)

# --- 依赖 ---
var _character: Character

# --- 内部结构定义 ---
# 用于封装单个部位的装备数据
class _ArmorData:
	var uuid: int = 0
	var instance: Node = null
	func _init(p_uuid: int, p_instance: Node):
		uuid = p_uuid
		instance = p_instance

# --- 内部状态 ---
var _armor_attachments_dictionary: Dictionary = {} # key: PbArmor.ArmorType, value: BoneAttachment3D
var _armor_equipped_dictionary: Dictionary = {} # key: PbArmor.ArmorType, value: _ArmorData

# --- 初始化 ---
func setup(character: Character) -> void:
	_character = character
	name = "ArmorMgr"

# 装备
func equip_armor(uuid: int) -> void:
	var cfg = GPlayerData.get_armor_cfg_by_uuid(uuid)
	var res_data = load(cfg.resPath) as ArmorData

	# 卸下同位置旧装备
	unequip_armor(cfg.type)

	# 获取挂点 (没有则创建)
	var attachment = _get_or_create_attachment(cfg.type)
	if not attachment:
		push_error("ArmorMgr: Failed to create attachment for socket: " + cfg.type)
		return

	# 加载场景
	var scene = load(res_data.scene_path)
	if not scene:
		push_error("ArmorMgr: Failed to load scene: " + res_data.scene_path)
		return

	var instance = scene.instantiate()
	attachment.add_child(instance)

	var armorData = _ArmorData.new(uuid, instance)
	_armor_equipped_dictionary[cfg.type] = armorData

	armor_equipped.emit(uuid)
	print("EquipmentMgr: Equipped armor %d on %s" % [uuid, cfg.type])

# 卸下
func unequip_armor(armor_type: PbArmor.ArmorType) -> void:
	if !_armor_equipped_dictionary.has(armor_type): # 没有
		return
	var armorData = _armor_equipped_dictionary[armor_type]
	armorData.instance.queue_free()
	_armor_equipped_dictionary.erase(armor_type)
	armor_unequipped.emit(armor_type)

# --- 辅助 ---
func _get_or_create_attachment(armor_type: PbArmor.ArmorType) -> BoneAttachment3D:
	var bone_name: String
	match armor_type:
		PbArmor.ArmorType.ArmorType_Helmet:
			bone_name = "Head"
	assert(bone_name != "armor 类型 不支持 %d" % armor_type)
	# 检查缓存
	if _armor_attachments_dictionary.has(bone_name):
		return _armor_attachments_dictionary[bone_name]

	# 检查场景中是否已经手动创建了
	# 遍历 Skeleton 的子节点找 BoneAttachment3D
	for child in _character.skeleton.get_children():
		if child is BoneAttachment3D and child.bone_name == bone_name:
			_armor_attachments_dictionary[bone_name] = child
			return child

	var attachment = BoneAttachment3D.new()
	attachment.bone_name = bone_name
	attachment.name = bone_name + "Attachment"
	_character.skeleton.add_child(attachment)

	_armor_attachments_dictionary[bone_name] = attachment # Cache original key
	return attachment

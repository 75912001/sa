class_name ArmorMgr extends Node

# --- 信号 ---
signal armor_equipped(armor_uuid: int)
signal armor_unequipped(armor_type: PbArmor.ArmorType)

# --- 依赖 ---
var _skeleton: Skeleton3D

# --- 内部状态 ---
var _armor_attachments_dictionary: Dictionary = {} # key: PbArmor.ArmorType, value: BoneAttachment3D
var _armor_equipped_dictionary: Dictionary = {} # key: PbArmor.ArmorType, value: armor_uuid (int)
var _armor_instances_dictionary: Dictionary = {} # key: PbArmor.ArmorType, value: Node (Instance)

# --- 配置---
# 这里暂时硬编码，以后可以改为从 yaml 加载
var _armor_configs := {
	12000001: preload("res://Assets/Equipment/Helmet/Helmet.001/data.tres")
}

# --- 初始化 ---
func setup(skeleton: Skeleton3D) -> void:
	_skeleton = skeleton

	# 从 Save 数据读取并装备护甲
	var equipped_data = GSave.character_record.get_ArmorEquippedData()
	var armor_list = equipped_data.get_ArmorUUIDList()
	# 装备所有护甲
	for armor_uuid in armor_list:
		if 0 < armor_uuid:
			equip_armor(armor_uuid)

# 装备
func equip_armor(uuid: int) -> void:
	var cfg = GPlayerData.get_armor_cfg_by_uuid(uuid)
	
	# 获取配置
	if not _armor_configs.has(cfg.id):
		push_warning("EquipmentMgr: Unknown armor id: %d" % cfg.id)
		return

	var data: ArmorData = _armor_configs[cfg.id]

	# 卸下同位置旧装备
	unequip_armor(cfg.type)

	# 获取挂点 (没有则创建)
	var attachment = _get_or_create_attachment(cfg.type)
	if not attachment:
		push_error("EquipmentMgr: Failed to create attachment for socket: " + cfg.type)
		return

	# 加载场景
	var scene = load(data.scene_path)
	if not scene:
		push_error("EquipmentMgr: Failed to load scene: " + data.scene_path)
		return

	var instance = scene.instantiate()
	attachment.add_child(instance)

	_armor_instances_dictionary[cfg.type] = instance
	_armor_equipped_dictionary[cfg.type] = uuid

	armor_equipped.emit(uuid)
	print("EquipmentMgr: Equipped armor %d on %s" % [uuid, cfg.type])

# 卸下
func unequip_armor(armor_type: PbArmor.ArmorType) -> void:
	if !_armor_instances_dictionary.has(armor_type): # 没有
		return
	var instance = _armor_instances_dictionary[armor_type]
	instance.queue_free()
	_armor_instances_dictionary.erase(armor_type)
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
	for child in _skeleton.get_children():
		if child is BoneAttachment3D and child.bone_name == bone_name:
			_armor_attachments_dictionary[bone_name] = child
			return child

	# 动态创建
	if _skeleton.find_bone(bone_name) == -1:
		push_warning("EquipmentMgr: Bone not found: " + bone_name + ". Trying Mixamorig prefix...")
		# 尝试加上常用的 Mixamo 前缀
		var mixamo_name = "Mixamorig:" + bone_name
		if _skeleton.find_bone(mixamo_name) != -1:
			bone_name = mixamo_name
		else:
			push_error("EquipmentMgr: Bone absolutely not found: " + bone_name)
			return null

	var attachment = BoneAttachment3D.new()
	attachment.bone_name = bone_name
	attachment.name = bone_name + "Attachment"
	_skeleton.add_child(attachment)

	_armor_attachments_dictionary[bone_name] = attachment # Cache original key
	return attachment

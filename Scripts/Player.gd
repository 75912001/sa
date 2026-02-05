extends Character
# 玩家
#
# 职责：
# - 作为全局玩家引用（GGameMgr.player）
# - 所有其他功能都继承自Character
#
# 说明：
# 所有通用逻辑 Character.gd
# Player只需做玩家特化的初始化

func _ready() -> void:
	GGameMgr.player = self
	input_mgr = $InputMgr

	super._ready()

	# 从 Save 数据读取并装备护甲
	var equipped_data = GSave.character_record.get_ArmorEquippedData()
	var armor_list = equipped_data.get_ArmorUUIDList()
	# 装备所有护甲
	for armor_uuid in armor_list:
		if 0 < armor_uuid:
			armor_mgr.equip_armor(armor_uuid)

	# 根据存档初始化武器
	var right_hand_weapon_uuid = GPlayerData.get_right_hand_weapon_uuid()
	if right_hand_weapon_uuid != 0:
		weapon_mgr.equip_weapon_by_uuid(right_hand_weapon_uuid)
	return

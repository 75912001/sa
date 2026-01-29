extends Character
# 玩家-协调者

func _ready_subclass() -> void:
	GGameMgr.player = self

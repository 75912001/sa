# 基本要求
    阅读 README.md
    深度思考
    分析背景
    明确问题
    评审当前想法
    查阅可参考资料
    完成任务
    给出详细的解决方案.
    注重逻辑清晰和步骤明确.
    不要直接给出代码实现, 而是给出如何实现的思路.
    注重性能和可维护性.
    如若有更好的方``案, 请一并给出.并给出理由和对比.
    可以完全访问当前项目的代码和资源.
    细化方案,做成步骤,一边实现,一边验证,逐步实现.
# 背景
    当前地图需要刷NPC.
# 问题
      
# 当前想法
    NPC使用 D:\sa\Scripts\Character.gd 这样就能使用 通用的角色逻辑.
# 可参考资料

# 任务
    在任务没有完全完成之前, 不要停止回答. 持续思考, 找到最佳方案. 在提问和回答中不断完善方案.
    非常详细的一步步指引我完成.
    给出方案. 将解决方案分步骤列出.写入 plan.md 下方的 "# 解决方案" 处.
# 解决方案

## 问题根因分析

**错误信息**：`Attempt to call function 'get_move_vector' in base 'null instance' on a null instance`

**根因链**：
1. `Character.gd:33` 的 `@onready var input_mgr: IInputProvider = $InputMgr` 假设场景有 InputMgr 节点
2. NPC.tscn 只有 AIInputMgr 节点，没有 InputMgr 节点
3. 因此 NPC 的 input_mgr 被初始化为 null
4. `Character._ready()` 先调用 `_init_animation_mgr()`（第64行），再调用 `_ready_subclass()`（第67行）
5. NPC._ready_subclass() 中的 `input_mgr = $AIInputMgr` 设置太晚
6. animation_mgr.input_mgr 已经被设置为 null

**次要问题**：
- `AnimationMgr.gd:15` 类型写死为 `InputMgr`，应为 `IInputProvider`
- `AnimationMgr.gd:149` 的 `assert(false)` 会崩溃
- `AnimationMgr.gd:156/164` 使用 `GPlayerData` 只对 Player 有效

---

## 步骤 1：移除 Character.gd 中 input_mgr 的 @onready 初始化

**目标**：让 input_mgr 不在 @onready 时初始化，避免 NPC 场景因找不到 InputMgr 节点而失败

**文件**：`D:\sa\Scripts\Character.gd`

**修改**：第 33 行
```gdscript
# 修改前：
@onready var input_mgr: IInputProvider = $InputMgr

# 修改后：
var input_mgr: IInputProvider
```

**验证方法**：
- 运行游戏，确认 Player 和 NPC 都能加载（可能有其他错误，但不应该是 "Node not found: InputMgr"）

---

## 步骤 2：调整 Character._ready() 的初始化顺序

**目标**：让 _ready_subclass() 在管理器初始化之前执行，使子类能先设置 input_mgr

**文件**：`D:\sa\Scripts\Character.gd`

**修改**：第 57-67 行，将 `_ready_subclass()` 移到管理器初始化之前

```gdscript
# 修改前（第57-67行）：
	# 初始化所有管理器
	_init_armor_mgr()
	_init_weapon_mgr()
	_init_weapon_switch_mgr()
	_init_attack_mgr()
	_init_movement_mgr()
	_init_roll_mgr()
	_init_animation_mgr()

	# 子类特化初始化
	_ready_subclass()

# 修改后：
	# 子类特化初始化（让子类先设置 input_mgr 等）
	_ready_subclass()

	# 初始化所有管理器
	_init_armor_mgr()
	_init_weapon_mgr()
	_init_weapon_switch_mgr()
	_init_attack_mgr()
	_init_movement_mgr()
	_init_roll_mgr()
	_init_animation_mgr()
```

**验证方法**：
- 运行游戏
- 检查控制台输出，确认 Player 和 NPC 的 _ready_subclass() 被调用
- 添加临时 print 语句验证 input_mgr 在 _init_animation_mgr() 前不为 null

---

## 步骤 3：修复 AnimationMgr.input_mgr 的类型声明

**目标**：将 input_mgr 的类型从 InputMgr 改为 IInputProvider，支持多态

**文件**：`D:\sa\Scripts\Animation\AnimationMgr.gd`

**修改**：第 15 行
```gdscript
# 修改前：
var input_mgr: InputMgr

# 修改后：
var input_mgr: IInputProvider
```

**验证方法**：
- 保存文件
- 确认 Godot 编辑器不报类型错误
- 运行游戏，确认 Player 和 NPC 都能正常初始化

---

## 步骤 4：修复 AnimationMgr.update_upper_animation() 的 assert

**目标**：移除会导致崩溃的 assert(false)，添加基本的上半身 idle 逻辑

**文件**：`D:\sa\Scripts\Animation\AnimationMgr.gd`

**修改**：第 148-151 行
```gdscript
# 修改前：
	# idle
	assert(false, "todo menglc ... update_upper_animation idle...")
	#play_upper("SwordAndShield_Idle")
	return

# 修改后：
	# idle - 有武器时播放持剑待机
	play_upper("SwordAndShield_Idle")
```

**验证方法**：
- 运行游戏
- Player 持剑时静止，观察上半身是否播放 SwordAndShield_Idle 动画
- 确认不会崩溃

---

## 步骤 5：修复 AnimationMgr 中的 GPlayerData 调用（NPC 兼容）

**目标**：让 _pose_neutral_left_weapon() 和 _pose_neutral_right_weapon() 对 NPC 也能工作

**问题分析**：
- 当前代码使用 `GPlayerData.get_left_weapon_cfg()` 和 `GPlayerData.get_right_weapon_cfg()`
- GPlayerData 只存储 Player 的数据，NPC 调用这些方法会返回 Player 的武器信息

**文件**：`D:\sa\Scripts\Animation\AnimationMgr.gd`

**方案A（推荐，改动小）**：在 AnimationMgr 中添加 weapon_mgr 引用

**修改1**：第 21 行附近添加
```gdscript
var weapon_mgr: WeaponMgr  # 武器管理器引用
```

**修改2**：Character.gd 的 _init_animation_mgr() 中添加设置
```gdscript
# D:\sa\Scripts\Character.gd 第157-163行
func _init_animation_mgr() -> void:
	# 设置引用
	animation_mgr.input_mgr = input_mgr
	animation_mgr.movement_mgr = movement_mgr
	animation_mgr.weapon_switch_mgr = weapon_switch_mgr
	animation_mgr.attack_mgr = attack_mgr
	animation_mgr.roll_mgr = roll_mgr
	animation_mgr.weapon_mgr = weapon_mgr  # 添加这行
```

**修改3**：修改 _pose_neutral_right_weapon()（第 162-167 行）
```gdscript
# 修改前：
func _pose_neutral_right_weapon() -> bool:
	var right_weapon_type = PbWeapon.WeaponType.WeaponType_Unarmed
	var right_weapon_cfg = GPlayerData.get_right_weapon_cfg()
	if right_weapon_cfg != null:
		right_weapon_type = right_weapon_cfg.type
	return _pose_neutral_weapon(right_weapon_type)

# 修改后：
func _pose_neutral_right_weapon() -> bool:
	var right_weapon_type = PbWeapon.WeaponType.WeaponType_Unarmed
	if weapon_mgr and weapon_mgr.get_current_weapon_uuid() != 0:
		var weapon_uuid = weapon_mgr.get_current_weapon_uuid()
		var weapon_cfg = GPlayerData.get_weapon_cfg_by_uuid(weapon_uuid)
		if weapon_cfg != null:
			right_weapon_type = weapon_cfg.type
	return _pose_neutral_weapon(right_weapon_type)
```

**修改4**：类似修改 _pose_neutral_left_weapon()（暂时返回 true，因为左手武器系统未实现）
```gdscript
# 修改后：
func _pose_neutral_left_weapon() -> bool:
	# TODO: 左手武器系统未实现，暂时返回 true
	return true
```

**验证方法**：
- 运行游戏
- Player 持剑时应该进入 SPLIT 模式（上下半身分离动画）
- NPC 无武器时应该进入 FULL_BODY 模式

---

## 步骤 6：验证完整功能

**验证清单**：

| 场景 | 预期行为 | 验证方法 |
|------|----------|----------|
| Player 无武器静止 | 全身 Idle 动画 | 观察动画 |
| Player 无武器移动 | 全身 Walking 动画 | WASD 移动 |
| Player 持剑静止 | 上半身 SwordAndShield_Idle | 装备武器后观察 |
| Player 持剑移动 | 下半身 Walking，上半身 SwordAndShield_Idle | 装备后移动 |
| NPC 生成 | 不崩溃，显示 Idle 动画 | 在场景中放置 NPC |
| NPC 动画 | 播放 Unarmed_Idle | 观察 NPC |

---

## 执行顺序总结

1. **步骤 1**：移除 @onready input_mgr 初始化 → 验证
2. **步骤 2**：调整 _ready_subclass() 顺序 → 验证
3. **步骤 3**：修复 AnimationMgr.input_mgr 类型 → 验证
4. **步骤 4**：移除 assert(false) → 验证
5. **步骤 5**：修复 GPlayerData 调用 → 验证
6. **步骤 6**：完整功能验证

每步修改后都运行游戏验证，确保不引入新问题。


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
    如若有更好的方案, 请一并给出.并给出理由和对比.
    可以完全访问当前项目的代码和资源.
# 背景
      切换武器时,没有拔剑的动作,直接切换
# 问题
      切换武器时,动作不自然,需要增加拔剑动作.
      Unarmed -> Sword
      Sword -> Sword
# 当前想法
      Unarmed -> Sword : 空手->持剑
         播放拔剑动作
            D:\sa\Assets\Animations\Library\Unarmed\DrawSword.res 空手,去握剑柄
         播放拔剑动作
            D:\sa\Assets\Animations\Library\SwordAndShield\DrawSword.res 拔剑动作,动画播放开始时装备武器
      Sword -> Sword : 持剑->持剑
         播放收剑动作
         D:\sa\Assets\Animations\Library\SwordAndShield\SheathSword.1.res 收剑动作,动画播放结束时-卸下武器
         播放拔剑动作
         D:\sa\Assets\Animations\Library\SwordAndShield\DrawSword.res 拔剑动作,动画播放开始时-装备武器
      Sword -> Unarmed : 持剑->空手
         播放收剑动作
         D:\sa\Assets\Animations\Library\SwordAndShield\SheathSword.1.res 收剑动作,动画播放结束时-卸下武器
         恢复空手状态
         D:\sa\Assets\Animations\Library\SwordAndShield\SheathSword.2.res
# 可参考资料
# 任务
    非常详细的一步步指引我完成.
    给出方案. 将解决方案分步骤列出.写入 plan.md 下方的 "# 解决方案" 处.
# 解决方案

## 分析总结

### 动画资源（已存在 ✓）
| 动画 | 路径 | 用途 |
|------|------|------|
| Unarmed_DrawSword | `Unarmed/DrawSword.res` | 空手去握剑柄 |
| SwordAndShield_DrawSword | `SwordAndShield/DrawSword.res` | 拔剑动画 |
| SwordAndShield_SheathSword_1 | `SwordAndShield/SheathSword.1.res` | 收剑阶段1 |
| SwordAndShield_SheathSword_2 | `SwordAndShield/SheathSword.2.res` | 收剑阶段2（手臂归位）|

### 当前系统限制
- AnimationMgr：无动画队列、无完成回调
- WeaponMgr：立即装备/卸下，无动画协调
- 无切换过程中的输入锁定

### 当前想法评审
用户的动画流程设计合理：
- ✓ 拔剑分两阶段（空手握柄 → 持剑拔出）
- ✓ 收剑分两阶段（收入剑鞘 → 手臂归位）
- ✓ 武器模型在动画特定时机出现/消失

---

## 架构设计

### 新增组件：WeaponSwitchMgr（武器切换管理器）

遵循现有的 Manager Pattern，新增一个专门处理武器切换动画序列的管理器：

```
Player (协调者)
├── MovementMgr      - 移动（已有 lock/unlock）
├── JumpMgr          - 跳跃
├── AnimationMgr     - 动画（需增强：队列 + 回调）
├── WeaponMgr        - 武器（需增强：延迟装备）
└── WeaponSwitchMgr  - 【新增】切换动画编排
```

---

## 实施步骤

### 第一步：增强 AnimationMgr

**文件**: `Scripts/Animation.gd`

**新增内容**:
```gdscript
# --- 信号 ---
signal animation_finished(animation_name: String)
signal sequence_finished()

# --- 变量 ---
var _animation_queue: Array[String] = []
var _is_playing_sequence := false

func _ready() -> void:
    # ... 原有代码 ...
    # 连接 AnimationTree 的动画完成信号
    _animation_tree.animation_finished.connect(_on_animation_finished)

# 播放动画序列
func play_sequence(animations: Array[String]) -> void:
    _animation_queue = animations.duplicate()
    _is_playing_sequence = true
    _play_next_in_queue()

# 内部：播放队列中下一个动画
func _play_next_in_queue() -> void:
    if _animation_queue.is_empty():
        _is_playing_sequence = false
        sequence_finished.emit()
        return
    var next_anim = _animation_queue.pop_front()
    play(next_anim)

# 内部：动画完成回调
func _on_animation_finished(anim_name: StringName) -> void:
    animation_finished.emit(str(anim_name))
    if _is_playing_sequence:
        _play_next_in_queue()

# 是否正在播放序列
func is_in_sequence() -> bool:
    return _is_playing_sequence
```

---

### 第二步：增强 WeaponMgr

**文件**: `Scripts/Weapon/WeaponMgr.gd`

**新增内容**:
```gdscript
# --- 变量 ---
var _is_switch_locked := false  # 切换锁定

# 锁定/解锁输入
func lock_input() -> void:
    _is_switch_locked = true

func unlock_input() -> void:
    _is_switch_locked = false

# 仅装备武器模型（不处理输入，供 WeaponSwitchMgr 调用）
func equip_weapon_model(slot: int) -> void:
    if not _weapon_configs.has(slot):
        return
    var config: WeaponData = _weapon_configs[slot]
    var weapon_scene: PackedScene = load(config.scene_path)
    if not weapon_scene:
        return
    var weapon_instance: Weapon = weapon_scene.instantiate()
    weapon_instance.weapon_data = config
    _weapon_attachment.add_child(weapon_instance)
    _current_weapon = weapon_instance
    _current_slot = slot
    weapon_equipped.emit(config.weapon_name)

# 仅卸下武器模型
func unequip_weapon_model() -> void:
    if _current_weapon:
        _current_weapon.queue_free()
        _current_weapon = null
        _current_slot = 0
        weapon_unequipped.emit()

# 获取切换类型
func get_switch_type(target_slot: int) -> String:
    var has_current = has_weapon()
    var has_target = target_slot > 0 and _weapon_configs.has(target_slot)

    if not has_current and has_target:
        return "unarmed_to_sword"
    elif has_current and has_target and target_slot != _current_slot:
        return "sword_to_sword"
    elif has_current and (target_slot == 0 or target_slot == _current_slot):
        return "sword_to_unarmed"
    return ""

# 修改 handle_input
func handle_input() -> void:
    if _input_cooldown or _is_switch_locked:  # 新增锁定检查
        return
    # ... 原有代码 ...
```

---

### 第三步：创建 WeaponSwitchMgr

**新建文件**: `Scripts/Weapon/WeaponSwitchMgr.gd`

```gdscript
extends Node
class_name WeaponSwitchMgr
## 武器切换管理器 - 编排切换动画序列

# --- 信号 ---
signal switch_started()
signal switch_completed()

# --- 状态 ---
enum State { IDLE, SWITCHING }
var _state: State = State.IDLE
var _target_slot: int = 0

# --- 引用（在 Player.gd 中设置）---
var animation_mgr: AnimationMgr
var weapon_mgr: WeaponMgr
var movement_mgr: MovementMgr

# --- 时序配置（秒）---
const SHEATH_UNEQUIP_DELAY := 0.6  # 收剑动画多久后卸下武器

## 开始武器切换
func start_switch(target_slot: int) -> bool:
    if _state != State.IDLE:
        return false

    var switch_type = weapon_mgr.get_switch_type(target_slot)
    if switch_type.is_empty():
        return false

    _state = State.SWITCHING
    _target_slot = target_slot

    # 锁定输入
    movement_mgr.lock()
    weapon_mgr.lock_input()
    switch_started.emit()

    # 根据类型执行对应流程
    match switch_type:
        "unarmed_to_sword":
            _do_unarmed_to_sword()
        "sword_to_sword":
            _do_sword_to_sword()
        "sword_to_unarmed":
            _do_sword_to_unarmed()

    return true

## 流程：空手 → 持剑
func _do_unarmed_to_sword() -> void:
    # 1. 空手去握剑柄
    animation_mgr.play("Unarmed_DrawSword")
    await animation_mgr.animation_finished

    # 2. 装备武器模型
    weapon_mgr.equip_weapon_model(_target_slot)

    # 3. 拔剑动画
    animation_mgr.play("SwordAndShield_DrawSword")
    await animation_mgr.animation_finished

    _finish_switch()

## 流程：持剑 → 持剑（换武器）
func _do_sword_to_sword() -> void:
    # 1. 收剑动画
    animation_mgr.play("SwordAndShield_SheathSword_1")

    # 2. 延迟后卸下当前武器
    await get_tree().create_timer(SHEATH_UNEQUIP_DELAY).timeout
    weapon_mgr.unequip_weapon_model()

    await animation_mgr.animation_finished

    # 3. 装备新武器
    weapon_mgr.equip_weapon_model(_target_slot)

    # 4. 拔剑动画
    animation_mgr.play("SwordAndShield_DrawSword")
    await animation_mgr.animation_finished

    _finish_switch()

## 流程：持剑 → 空手
func _do_sword_to_unarmed() -> void:
    # 1. 收剑动画
    animation_mgr.play("SwordAndShield_SheathSword_1")

    # 2. 延迟后卸下武器
    await get_tree().create_timer(SHEATH_UNEQUIP_DELAY).timeout
    weapon_mgr.unequip_weapon_model()

    await animation_mgr.animation_finished

    # 3. 手臂归位动画
    animation_mgr.play("SwordAndShield_SheathSword_2")
    await animation_mgr.animation_finished

    _finish_switch()

## 完成切换
func _finish_switch() -> void:
    _state = State.IDLE
    movement_mgr.unlock()
    weapon_mgr.unlock_input()
    switch_completed.emit()

## 是否正在切换
func is_switching() -> bool:
    return _state == State.SWITCHING
```

---

### 第四步：修改 Player 场景和脚本

**4.1 修改 Player.tscn**

1. 在 Player 节点下添加子节点 `WeaponSwitchMgr` (类型: Node)
2. 附加脚本 `Scripts/Weapon/WeaponSwitchMgr.gd`

**4.2 修改 Player.gd**

```gdscript
# --- 组件引用 ---
@onready var weapon_switch_mgr: WeaponSwitchMgr = $WeaponSwitchMgr

func _ready() -> void:
    _init_jump_mgr()
    _init_weapon_mgr()
    _init_weapon_switch_mgr()  # 新增

func _init_weapon_switch_mgr() -> void:
    # 设置引用
    weapon_switch_mgr.animation_mgr = animation_mgr
    weapon_switch_mgr.weapon_mgr = weapon_mgr
    weapon_switch_mgr.movement_mgr = movement_mgr
    # 连接信号
    weapon_switch_mgr.switch_started.connect(_on_weapon_switch_started)
    weapon_switch_mgr.switch_completed.connect(_on_weapon_switch_completed)

func _on_weapon_switch_started() -> void:
    prints("weapon switch started")

func _on_weapon_switch_completed() -> void:
    prints("weapon switch completed")
```

---

### 第五步：修改武器输入处理

**修改 WeaponMgr.handle_input()**，改为通过 WeaponSwitchMgr 处理：

**方案 A**：在 WeaponMgr 中直接调用 WeaponSwitchMgr（需要引用）

**方案 B（推荐）**：在 Player.gd 中拦截武器输入

```gdscript
# Player.gd
func _physics_process(delta: float) -> void:
    movement_mgr.handle_input(delta)
    jump_mgr.handle_input()
    _handle_weapon_input()  # 替换 weapon_mgr.handle_input()
    # ... 其余代码 ...

func _handle_weapon_input() -> void:
    if weapon_switch_mgr.is_switching():
        return

    # Alt + 数字键检测
    if Input.is_key_pressed(KEY_ALT):
        for i in range(10):
            if Input.is_key_pressed(KEY_0 + i):
                weapon_switch_mgr.start_switch(i)
                return
```

---

### 第六步：配置 AnimationTree 状态机

在 Godot 编辑器中为 AnimationTree 添加以下动画状态（如果尚未添加）：

1. 打开 `Scenes/Player.tscn`
2. 选择 `XBot/AnimationTree`
3. 在状态机中确保存在以下状态：
   - `Unarmed_DrawSword`
   - `SwordAndShield_DrawSword`
   - `SwordAndShield_SheathSword_1`
   - `SwordAndShield_SheathSword_2`

4. 配置转场（Transitions）：使用默认设置即可，因为我们通过代码控制播放

---

### 第七步：测试

1. **测试 Unarmed → Sword**
   - 空手状态按 Alt+1
   - 观察：先播放握剑柄动画 → 武器出现 → 拔剑动画 → 持剑待机

2. **测试 Sword → Sword**
   - 持剑状态按 Alt+2（切换到另一把剑）
   - 观察：收剑动画 → 武器消失 → 新武器出现 → 拔剑动画 → 持剑待机

3. **测试 Sword → Unarmed**
   - 持剑状态按 Alt+0 或再按 Alt+1
   - 观察：收剑动画 → 武器消失 → 手臂归位动画 → 空手待机

4. **测试输入锁定**
   - 切换过程中尝试移动/跳跃
   - 应该被锁定，无响应

---

## 文件清单

| 操作 | 文件 |
|------|------|
| 修改 | `Scripts/Animation.gd` - 添加队列和回调 |
| 修改 | `Scripts/Weapon/WeaponMgr.gd` - 添加延迟装备/锁定 |
| 修改 | `Scripts/Player.gd` - 集成 WeaponSwitchMgr |
| 修改 | `Scenes/Player.tscn` - 添加 WeaponSwitchMgr 节点 |
| 新建 | `Scripts/Weapon/WeaponSwitchMgr.gd` - 切换动画编排 |

---

## 时序参数调整

如果动画时机不准确，调整 `WeaponSwitchMgr` 中的常量：

```gdscript
const SHEATH_UNEQUIP_DELAY := 0.6  # 收剑后多久卸下武器（秒）
```

可根据实际动画长度微调此值。


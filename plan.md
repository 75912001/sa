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
      当前动画都是固定时间.
# 问题
      是否可以,在代码层, 或者配置层来配置, 不同的武器, 使用相同的动作, 但是不同的动画时间.
      例如, 现在是 SwordAndShield_Attack_Slash_2_8, 
         使用的武器是 11000001, 原来的动画时长
         使用的武器是 11000002, 希望动画时长变为 3.2 秒. (指定时长)
      
# 当前想法
# 可参考资料
      D:\sa\Cfg\weapon.yaml 武器配置表, 用来配置时间, 毫秒数
      D:\sa\Scripts\Animation\AttackMgr.gd 攻击管理器
# 任务
    在任务没有完全完成之前, 不要停止回答. 持续思考, 找到最佳方案. 在提问和回答中不断完善方案.
    非常详细的一步步指引我完成.
    给出方案. 将解决方案分步骤列出.写入 plan.md 下方的 "# 解决方案" 处.
# 解决方案

## 分析

**核心问题**：当前动画时长由 Animation 资源固定（如 `Attack.Slash.2.8.res` = 2.8秒），需要让不同武器使用相同动画但有不同播放时长。

**Godot 动画速度控制方式**：
| 方式 | 优点 | 缺点 |
|-----|------|------|
| AnimationNodeTimeScale 节点 | 只影响特定动画路径，精确控制 | 需要修改 AnimationTree 结构 |
| AnimationPlayer.speed_scale | 简单，无需改结构 | 影响所有动画（全局） |
| 修改 Animation 资源 | 无 | 破坏原始资源，不可行 |

**推荐方案**：使用 **AnimationNodeTimeScale** 节点 + 配置驱动

**速度计算公式**：
```
speed_scale = 原始时长 / 目标时长
例如：原始 2.8 秒，目标 3.2 秒 → speed_scale = 2.8 / 3.2 = 0.875
```

---

## 实现步骤

### 步骤1：修改 weapon.yaml 添加动画时长配置

**文件**：`Cfg/weapon.yaml`

```yaml
weapons:
  - id: 11000001
    name: "武器-11000001"
    type: 1
    attack: 10
    description: "description-武器-11000001"
    # 不配置 attack_duration_ms，使用原始动画时长

  - id: 11000002
    name: "武器-11000002"
    type: 2
    attack: 20
    description: "description-武器-11000002"
    attack_duration_ms: 3200  # 攻击动画时长 3.2 秒
```

**设计说明**：
- `attack_duration_ms` 为可选字段，单位毫秒
- 不配置时使用原始动画时长（不做速度调整）
- 毫秒单位避免浮点精度问题，与服务端对齐

---

### 步骤2：修改 CfgWeaponEntry 添加属性

**文件**：`Scripts/Cfg/Weapon.gd`

在 `CfgWeaponEntry` 类中添加：
```gdscript
class CfgWeaponEntry extends RefCounted:
    var id: int
    var name: String
    var type: PbWeapon.WeaponType
    var attack: int
    var description: String
    var attack_duration_ms: int = 0  # 新增：攻击动画时长（毫秒），0 表示使用原始时长
```

在 `load()` 函数中添加解析：
```gdscript
entry.attack_duration_ms = item.get("attack_duration_ms", 0)
```

---

### 步骤3：修改 AnimationTree 添加 TimeScale 节点

**文件**：`Scenes/Player.tscn`（在 Godot 编辑器中操作）

**当前结构**：
```
Action_OneShot
└── Action_Type (Transition)
    ├── attack → Animation (Attack.Slash.2.8)
    └── roll → Roll
```

**修改后结构**：
```
Action_OneShot
└── Action_Type (Transition)
    ├── attack → Attack_TimeScale → Animation (Attack.Slash.2.8)
    └── roll → Roll
```

**编辑器操作步骤**：
1. 打开 `Scenes/Player.tscn`
2. 选中 `XBot/AnimationTree`
3. 在 BlendTree 面板中：
   - 添加节点：`AnimationNodeTimeScale`，命名为 `Attack_TimeScale`
   - 将原来 `Animation` 节点的输出断开
   - 连接：`Animation` → `Attack_TimeScale` → `Action_Type` 的 `attack` 端口
4. 保存场景

**新增参数路径**：`parameters/Attack_TimeScale/scale`

---

### 步骤4：修改 AnimationOneShot 支持速度参数

**文件**：`Scripts/Animation/AnimationOneShot.gd`

添加速度控制路径和方法：
```gdscript
# 攻击动画速度控制
const PATH_ATTACK_TIME_SCALE = "parameters/Attack_TimeScale/scale"

# 播放指定动作（支持速度缩放）
func play(action_name: String, speed_scale: float = 1.0) -> void:
    _current_action = action_name

    # 设置攻击动画速度（只对 attack 生效）
    if action_name == "attack":
        animation_mgr.animation_tree.set(PATH_ATTACK_TIME_SCALE, speed_scale)

    # 设置路由 (Transition)
    animation_mgr.animation_tree.set(PATH_TRANSITION, action_name)
    # 触发 OneShot
    animation_mgr.animation_tree.set(PATH_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

    action_started.emit(action_name)
    _monitor_loop()
```

---

### 步骤5：修改 AttackMgr 计算并传递速度

**文件**：`Scripts/Animation/AttackMgr.gd`

```gdscript
# 原始动画时长（秒）- 与 Animation 资源一致
const ATTACK_ANIMATION_DURATION := 2.8

# 执行攻击
func attack() -> void:
    var speed_scale = _calculate_attack_speed()
    animation_mgr.one_shot.play("attack", speed_scale)
    print("攻击-开始 speed_scale:", speed_scale)
    animation_mgr.lock_mgr.add_lock(LockMgr.ACT_ATTACKING)
    attack_started.emit()

# 计算攻击动画速度
func _calculate_attack_speed() -> float:
    var weapon_uuid = GPlayerData.get_right_hand_weapon_uuid()
    if weapon_uuid == 0:
        return 1.0

    var weapon_record = GPlayerData.get_weapon_record(weapon_uuid)
    if weapon_record == null:
        return 1.0

    var weapon_cfg = GCfgMgr.cfg_weapon_mgr.get_weapon(weapon_record.get_AssetID())
    if weapon_cfg == null:
        return 1.0

    # 如果未配置时长，使用原始速度
    if weapon_cfg.attack_duration_ms <= 0:
        return 1.0

    # 速度 = 原始时长 / 目标时长
    var target_duration = weapon_cfg.attack_duration_ms / 1000.0
    return ATTACK_ANIMATION_DURATION / target_duration
```

---

## 方案对比

| 方案 | 描述 | 优点 | 缺点 |
|-----|------|------|------|
| **TimeScale 节点**（推荐） | 在 AnimationTree 中添加速度控制节点 | 精确控制单个动画，不影响其他 | 需要修改 AnimationTree |
| AnimationPlayer.speed_scale | 全局速度调整 | 无需改结构 | 影响所有动画，需要频繁切换 |
| 多个 Animation 资源 | 每个武器一个动画资源 | 最灵活 | 资源膨胀，维护困难 |

---

## 扩展考虑

1. **多动作支持**：如果需要支持更多动作（如 roll、skill）的速度配置，可以：
   - 在 yaml 中添加 `action_durations` 字典
   - 在 AnimationTree 中为每个动作添加 TimeScale 节点

2. **武器类型默认值**：可以按武器类型设置默认动画时长，单个武器配置覆盖默认值

3. **攻击连招**：如果有多段攻击，每段可以独立配置时长

---

## 验证方法

1. 运行游戏，装备武器 11000001，观察攻击动画时长（应为原始 2.8 秒）
2. 切换到武器 11000002，观察攻击动画时长（应为 3.2 秒）
3. 在控制台查看 `speed_scale` 输出值是否正确
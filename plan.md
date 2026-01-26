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
      当前有 idle, walking, 切换武器,动作.
      上下半生动作分离.
# 问题
      现在 新增了动作 SwordAndShield_Attack_Slash_2_8, 
      D:\sa\Assets\Animations\Library\SwordAndShield\Attack.Slash.2.8.res
      D:\sa\Assets\Animations\Raw\SwordAndShield\SheathSword.2.fbx
      需要增加功能, 鼠标左键点击攻击, 播放该动作.
      播放完毕, 回到 idle 状态.
# 当前想法
# 可参考资料
# 任务
    在任务没有完全完成之前, 不要停止回答. 持续思考, 找到最佳方案. 在提问和回答中不断完善方案.
    非常详细的一步步指引我完成.
    给出方案. 将解决方案分步骤列出.写入 plan.md 下方的 "# 解决方案" 处.
# 解决方案

## 一、需求分析

| 项目 | 描述 |
|------|------|
| 触发方式 | 鼠标左键点击 |
| 前置条件 | 持有武器（SwordAndShield） |
| 动画 | SwordAndShield_Attack_Slash_2_8 |
| 模式 | SPLIT（上半身攻击，下半身可移动） |
| 结束后 | 回到 SwordAndShield_Idle |

## 二、实现步骤

### 步骤 1：配置输入映射

在 Godot 编辑器中：
1. 打开 **项目 → 项目设置 → 输入映射**
2. 添加新动作 `attack_right`
3. 绑定 **鼠标左键**

### 步骤 2：InputMgr 添加攻击检测

在 `Scripts/Input/InputMgr.gd` 中：

**2.1 添加变量**（第 12 行后）：
```gdscript
# 攻击-右手
var attack_right_pressed: bool = false
```

**2.2 添加检测**（_process 中，第 19 行后）：
```gdscript
# 攻击-右手
attack_right_pressed = Input.is_action_just_pressed("attack_right")
```

**2.3 添加获取函数**（文件末尾）：
```gdscript
# 如果需要阻断输入, 可以在这里加开关
func get_attack_right_pressed() -> bool:
    return attack_right_pressed
```

### 步骤 3：配置 AnimationTree

在 `upper_body_sm` 中：
1. 添加动画节点 `SwordAndShield_Attack`，选择 `SwordAndShield/Attack.Slash.2.8`
2. 添加转换线：
   - `SwordAndShield_Idle` → `SwordAndShield_Attack`（Advance Mode: Enabled）
   - `SwordAndShield_Attack` → `SwordAndShield_Idle`（Advance Mode: Auto，动画播完自动回 Idle）

### 步骤 4：创建 AttackMgr

新建 `Scripts/Combat/AttackMgr.gd`：

**职责**：
- 检测攻击输入
- 判断是否可以攻击（持有武器、不在攻击中）
- 播放攻击动画
- 跟踪攻击状态

**完整代码**：
```gdscript
# 攻击-管理器
class_name AttackMgr

extends Node

@export var input_mgr: InputMgr

# --- 信号 ---
signal attack_started()
signal attack_finished()

# --- 状态 ---
enum State {
	IDLE,      # 空闲
	ATTACKING, # 攻击中
}

# --- 变量 ---
var _state: State = State.IDLE

# --- 引用（在 Player.gd 中设置）---
var animation_mgr: AnimationMgr
var weapon_mgr: WeaponMgr
var weapon_switch_mgr: WeaponSwitchMgr

# 处理输入
func handle_input() -> void:
	if input_mgr.get_attack_right_pressed():
		_try_attack()

# 尝试攻击
func _try_attack() -> void:
	if not _can_attack():
		return
	_do_attack()

# 是否可以攻击
func _can_attack() -> bool:
	# 必须持有武器
	if not weapon_mgr.has_weapon():
		return false
	# 不能正在攻击中
	if is_attacking():
		return false
	# 不能正在切换武器
	if weapon_switch_mgr.is_switching():
		return false
	return true

# 执行攻击
func _do_attack() -> void:
	_state = State.ATTACKING
	attack_started.emit()

	# 播放攻击动画
	animation_mgr.play_upper("SwordAndShield_Attack")

	# 等待动画完成
	await animation_mgr.animation_finished

	# 检查节点是否仍然有效
	if not is_instance_valid(self):
		return

	_state = State.IDLE
	attack_finished.emit()

# 是否正在攻击
func is_attacking() -> bool:
	return _state == State.ATTACKING
```

**接口说明**：
| 方法 | 说明 |
|------|------|
| handle_input() | 每帧调用，检测输入 |
| is_attacking() -> bool | 是否正在攻击 |

**流程**：
1. 检测鼠标左键
2. 检查前置条件（has_weapon, not attacking, not switching）
3. 设置状态为 ATTACKING
4. 播放 `animation_mgr.play_upper("SwordAndShield_Attack")`
5. await animation_finished
6. 设置状态为 IDLE

### 步骤 5：集成到 Player

在 `Player.gd` 中：
1. 添加 AttackMgr 节点引用
2. 在 `_physics_process` 中调用 `attack_mgr.handle_input()`
3. 在 `_init_attack_mgr()` 中设置引用和连接信号

### 步骤 6：更新 AnimationMgr

在 `update_upper_animation()` 中：
- 添加攻击状态检查，攻击中不自动更新上半身

```gdscript
if attack_mgr.is_attacking():
    return
```

## 三、状态优先级

上半身动画优先级（从高到低）：
1. 攻击中 → 由 AttackMgr 控制
2. 切换武器中 → 由 WeaponSwitchMgr 控制
3. 持有武器 → SwordAndShield_Idle
4. 空手 → Unarmed_Idle

## 四、扩展考虑

| 功能 | 说明 |
|------|------|
| 连击系统 | 攻击中再按攻击，切换到下一段攻击动画 |
| 攻击打断 | 受击时打断攻击 |
| 攻击冷却 | 攻击后短暂冷却 |
| 移动限制 | 攻击时是否限制移动速度 |

当前先实现基础攻击，后续可扩展。

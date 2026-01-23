# 跳跃-管理器
class_name JumpMgr

extends Node

# --- 配置 ---
@export var jump_velocity: float = 2.9 # 向上速度
@export var squat_time: float = 0.8  # 蓄力时间（秒）

# --- 信号 ---
signal jump_started      # 开始蓄力
signal jump_executed     # 起跳（进入空中）
signal jump_landed       # 落地

# --- 状态枚举 ---
enum State { 
	IDLE, # 空闲
	SQUATTING, # 蓄力
	AIRBORNE # 空中
}
var ddd: Dictionary = {}  # 武器ID -> WeaponEntry
# --- 变量 ---
var _body: CharacterBody3D
var _state: State = State.IDLE

func _ready() -> void:
	_body = get_parent() as CharacterBody3D

# 处理-输入
func handle_input() -> void:
	if Input.is_key_pressed(KEY_SPACE) and _body.is_on_floor() and _state == State.IDLE:
		_start_squat()

# 处理-重力
func handle_gravity(delta: float) -> void:
	if not _body.is_on_floor():
		_body.velocity += _body.get_gravity() * delta
	else:
		if _state == State.AIRBORNE:
			_land()

# --- 状态查询 ---
func is_idle() -> bool:
	return _state == State.IDLE

func is_squatting() -> bool:
	return _state == State.SQUATTING

func is_airborne() -> bool:
	return _state == State.AIRBORNE

func is_jumping() -> bool:
	return _state != State.IDLE

# 物理检查：是否离地（包括跳跃和掉落）
func is_in_air() -> bool:
	return not _body.is_on_floor()

func _start_squat() -> void:
	_state = State.SQUATTING
	jump_started.emit()

	# 等待蓄力
	await get_tree().create_timer(squat_time).timeout
	if _state == State.SQUATTING and is_instance_valid(self):
		_execute_jump()

func _execute_jump() -> void:
	_body.velocity.y = jump_velocity
	_state = State.AIRBORNE
	jump_executed.emit()

func _land() -> void:
	_state = State.IDLE
	jump_landed.emit()

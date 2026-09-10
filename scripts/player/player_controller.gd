class_name PlayerController
extends CharacterBody2D

## 主角控制器（SPEC 6.1）：占位块人物，可走可跳可交互。

@export var move_speed: float = 130.0
@export var jump_velocity: float = -320.0
const GRAVITY: float = 700.0

var frozen: bool = false
var look_dir: int = 1
var nearby: Array[Area2D] = []

@onready var _animator: Node = get_node_or_null("PlayerAnimator")
@onready var _zone: Area2D = get_node_or_null("InteractZone")

func _ready() -> void:
	if _zone != null:
		_zone.area_entered.connect(_on_zone_entered)
		_zone.area_exited.connect(_on_zone_exited)

func _physics_process(delta: float) -> void:
	if frozen:
		velocity = Vector2.ZERO
		return
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		set_look_dir(1 if dir > 0 else -1)
	velocity.x = dir * move_speed
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	move_and_slide()
	if Input.is_action_just_pressed("interact"):
		_try_interact()

func set_look_dir(dir: int) -> void:
	look_dir = dir
	if _animator != null and _animator.has_method("set_look"):
		_animator.call("set_look", dir)

func freeze(v: bool) -> void:
	frozen = v
	velocity = Vector2.ZERO

func _on_zone_entered(area: Area2D) -> void:
	if area.has_method("on_interact") and not nearby.has(area):
		nearby.append(area)

func _on_zone_exited(area: Area2D) -> void:
	nearby.erase(area)


func knock(vx: float) -> void:
	if not frozen:
		velocity.x = vx

func _try_interact() -> void:
	for a: Area2D in nearby:
		if a.has_method("on_interact"):
			var hero := get_node_or_null("KenneyHero")
			if hero != null and hero.has_method("trigger_interact"):
				hero.call("trigger_interact")
			a.call("on_interact", self)
			return
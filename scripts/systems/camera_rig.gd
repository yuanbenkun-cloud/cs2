class_name CameraRig
extends Camera2D

## 相机（Phase 1 产出）：跟随 Player（position_smoothing_enabled）+ shake() 震屏。
## （实现细节：spec 未给该脚本路径，放 scripts/systems/，见 DEV_LOG。）

var _shake_remaining: float = 0.0
var _shake_strength: float = 4.0
var _shake_duration: float = 0.3

func _process(delta: float) -> void:
	if _shake_remaining > 0.0:
		_shake_remaining -= delta
		var t := maxf(_shake_remaining / _shake_duration, 0.0)
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength * t
		if _shake_remaining <= 0.0:
			offset = Vector2.ZERO

func shake(strength: float = 4.0, duration: float = 0.3) -> void:
	_shake_strength = strength
	_shake_duration = duration
	_shake_remaining = duration

extends Node

signal sanity_changed(new_value: float)
signal state_changed(new_state: int)
signal secret_ending_unlocked

const MAX_SANITY = 100.0
const SECRET_ENDING_THRESHOLD = 15.0
const MIN_PLAYTIME_FOR_ENDING = 60.0
const ZERO_SANITY_SPEED_MULT = 0.8

# Limita de sus a fiecărui sprite, de la cel mai rău (0) la cel mai bun (15)
const STATE_LIMITS = [0.0, 10.0, 15.0, 20.0, 25.0, 35.0, 45.0, 50.0, 55.0, 60.0, 65.0, 75.0, 85.0, 90.0, 95.0, 100.0]

var sanity: float = MAX_SANITY
var current_state: int = STATE_LIMITS.size() - 1
var tracking: bool = true

var _weighted_sum: float = 0.0
var _total_time: float = 0.0


func _process(delta):
	if not tracking:
		return
	_weighted_sum += sanity * delta
	_total_time += delta


func change(amount: float):
	set_sanity(sanity + amount)


func set_sanity(value: float):
	sanity = clamp(value, 0.0, MAX_SANITY)
	sanity_changed.emit(sanity)

	var new_state = _get_state(sanity)
	if new_state != current_state:
		current_state = new_state
		state_changed.emit(current_state)


func _get_state(value: float) -> int:
	for i in STATE_LIMITS.size():
		if value <= STATE_LIMITS[i]:
			return i
	return STATE_LIMITS.size() - 1


func get_difficulty() -> float:
	return 1.0 - sanity / MAX_SANITY


func scale_with_difficulty(easy_value: float, hard_value: float) -> float:
	return lerp(easy_value, hard_value, get_difficulty())


func get_average_sanity() -> float:
	if _total_time <= 0.0:
		return MAX_SANITY
	return _weighted_sum / _total_time


func check_secret_ending() -> bool:
	var unlocked = _total_time >= MIN_PLAYTIME_FOR_ENDING \
		and get_average_sanity() < SECRET_ENDING_THRESHOLD
	if unlocked:
		secret_ending_unlocked.emit()
	return unlocked

func is_empty() -> bool:     #AICI SE POT ADAUGA DEBUFFURI PE VIITOR!!!
	return sanity <= 0.0

func get_speed_mulyiplier() -> float:
	return ZERO_SANITY_SPEED_MULT if is_empty() else 1.0

func reset():
	sanity = MAX_SANITY
	current_state = _get_state(sanity)
	_weighted_sum = 0.0
	_total_time = 0.0
	

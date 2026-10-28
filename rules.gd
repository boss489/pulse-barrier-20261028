extends RefCounted
const W := 11
const H := 7
var levels: Array[Dictionary] = []

func _init() -> void:
	for n in range(21):
		var gates: Array[Dictionary] = []
		var count: int = 1 if n < 2 else (2 if n < 8 else 3)
		for j in range(count):
			var x: int = [4, 7, 9][j] if count == 3 else ([4, 7][j] if count == 2 else 5)
			var row: int = 1 + ((n * 3 + j * 4 + (n / 4)) % 5)
			gates.append({"x": x, "row": row, "offset": (n + j) % 3})
		var gem := Vector2i(2 + (n % 2), 1 + ((n * 2) % 5))
		levels.append({"gates": gates, "gem": gem, "name": room_name(n), "tempo": 1.0 + float(n / 7) * 0.12})

func room_name(n: int) -> String:
	if n < 3:
		return ["첫 숨", "엇박", "갈림길"][n]
	return ["유리 심장", "잔향의 복도", "밤의 회로", "역류", "푸른 파장", "낮은 주파수", "쌍둥이 맥", "열린 틈", "빗나간 박", "재빠른 그림자", "붉은 문턱", "긴 호흡", "소용돌이", "마지막 신호", "부서진 박자", "유성의 방", "침묵의 끝", "거대한 고동", "새벽의 출구"][n - 3]

func phase_at(tick: int) -> int:
	return posmod(tick / 60, 3)

func gate_phase(offset: int, tick: int) -> int:
	return posmod(phase_at(tick) + offset, 3)

func can_cross(_gate: int, offset: int, tick: int) -> bool:
	return gate_phase(offset, tick) != 1

func gate_at(level: Dictionary, a: Vector2i, b: Vector2i) -> Dictionary:
	for g: Dictionary in level.gates:
		if (a.x == g.x - 1 and b.x == g.x) or (b.x == g.x - 1 and a.x == g.x):
			return g
	return {}

func valid_step(level: Dictionary, a: Vector2i, b: Vector2i, tick: int) -> bool:
	if b.x < 0 or b.x >= W or b.y < 0 or b.y >= H:
		return false
	var g := gate_at(level, a, b)
	if not g.is_empty():
		return a.y == g.row and can_cross(0, g.offset, tick)
	return true

func route_exists(level: Dictionary) -> bool:
	var seen := {Vector2i(1, 3): true}
	var queue: Array[Vector2i] = [Vector2i(1, 3)]
	while not queue.is_empty():
		var a: Vector2i = queue.pop_front()
		if a == Vector2i(9, 3):
			return true
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var b := a + d
			if b.x < 0 or b.x >= W or b.y < 0 or b.y >= H or seen.has(b):
				continue
			var g := gate_at(level, a, b)
			if not g.is_empty() and a.y != g.row:
				continue
			seen[b] = true
			queue.append(b)
	return false

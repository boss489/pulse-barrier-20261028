extends SceneTree
const Rules = preload("res://rules.gd")
const FONT = preload("res://assets/NanumGothic-Regular.ttf")
func _initialize() -> void:
	var r = Rules.new()
	assert(r.levels.size() == 21, "3 tutorial + 18 campaign rooms")
	for i in range(21):
		var level: Dictionary = r.levels[i]
		assert(r.route_exists(level), "room must have a reachable exit")
		assert(level.gates.size() >= 1)
	assert(r.phase_at(0) == 0)
	assert(r.phase_at(60) == 1)
	assert(r.phase_at(120) == 2)
	assert(r.phase_at(180) == 0)
	assert(not r.can_cross(0, 0, 60))
	assert(r.can_cross(0, 0, 120))
	assert(r.can_cross(0, 0, 0))
	assert(r.can_cross(1, 1, 60))
	assert(not r.can_cross(1, 1, 0))
	assert(r.levels[3].gates != r.levels[20].gates)
	for character in "박동 장벽 예고 위험 안전 튜토리얼 성공 실패 다시하기":
		assert(FONT.has_char(character.unicode_at(0)), "Korean glyph is bundled: " + character)
	print("PASS 21 rooms, reachability, deterministic 60-tick phases, collision, route variation, Korean glyphs")
	quit()

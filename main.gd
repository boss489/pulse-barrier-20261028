extends Node2D
const Rules = preload("res://rules.gd")
const FONT = preload("res://assets/NanumGothic-Regular.ttf")
const SFX_STEP = preload("res://assets/step.wav")
const SFX_PULSE = preload("res://assets/pulse.wav")
const SFX_FAIL = preload("res://assets/fail.wav")
const SFX_WIN = preload("res://assets/win.wav")
const INK := Color("091826")
const PANEL := Color("10283a")
const CYAN := Color("6ee5da")
const GOLD := Color("ffd28c")
const RED := Color("ff6c82")
const LIGHT := Color("e8f4ef")
var rules := Rules.new()
var state := "title"
var stage := 0
var unlocked := 0
var total_gems := 0
var got_gem := false
var charge := 0
var pos := Vector2i(1, 3)
var tick := 0
var clock_fraction := 0.0
var freeze_frames := 0
var held := Vector2i.ZERO
var held_repeat := 0.0
var cursor_target := Vector2i(-1, -1)
var blink := 0.0
var shake := 0.0
var muted := false
var audio: AudioStreamPlayer
var cell := 59.0
var board := Vector2(92, 176)
var side := 792.0
var portrait := false
var ui_scale := 1.0
var ui_origin := Vector2.ZERO

func _ready() -> void:
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_window().min_size = Vector2i(300, 400)
	audio = AudioStreamPlayer.new()
	add_child(audio)
	load_save()
	layout()
	queue_redraw()

func layout() -> void:
	var size := get_viewport_rect().size
	portrait = size.y > size.x * 1.12
	var virtual := Vector2(560, 1210) if portrait else Vector2(960, 720)
	ui_scale = minf(size.x / virtual.x, size.y / virtual.y)
	ui_origin = (size - virtual * ui_scale) * 0.5
	cell = 45.0 if portrait else 59.0
	board = Vector2(31, 282) if portrait else Vector2(92, 176)
	side = 31.0 if portrait else 792.0

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "gems", total_gems)
	cfg.save("user://pulse_barrier.cfg")

func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://pulse_barrier.cfg") == OK:
		unlocked = clampi(int(cfg.get_value("progress", "unlocked", 0)), 0, 20)
		total_gems = maxi(0, int(cfg.get_value("progress", "gems", 0)))

func begin_room(index: int) -> void:
	stage = clampi(index, 0, 20)
	state = "play"
	pos = Vector2i(1, 3)
	tick = 0
	clock_fraction = 0.0
	freeze_frames = 0
	charge = 0
	got_gem = false
	held = Vector2i.ZERO
	cursor_target = Vector2i(-1, -1)
	play_sound(SFX_PULSE)
	queue_redraw()

func _physics_process(delta: float) -> void:
	layout()
	blink += delta
	shake = maxf(0.0, shake - delta * 8.0)
	if state == "play":
		if freeze_frames > 0:
			freeze_frames -= 1
		else:
			clock_fraction += rules.levels[stage].tempo
			while clock_fraction >= 1.0:
				tick += 1
				clock_fraction -= 1.0
				if tick % 60 == 0:
					play_sound(SFX_PULSE)
		if freeze_frames == 0:
			held_repeat -= delta
			if held != Vector2i.ZERO and held_repeat <= 0:
				step(held)
				held_repeat = 0.14
			elif cursor_target.x >= 0 and held_repeat <= 0:
				var diff := cursor_target - pos
				if diff == Vector2i.ZERO:
					cursor_target = Vector2i(-1, -1)
				else:
					step(Vector2i(signi(diff.x), 0) if diff.x != 0 else Vector2i(0, signi(diff.y)))
					held_repeat = 0.16
	queue_redraw()

func signi(n: int) -> int:
	return 1 if n > 0 else -1

func step(dir: Vector2i) -> void:
	if state != "play" or freeze_frames > 0:
		return
	var target := pos + dir
	var level: Dictionary = rules.levels[stage]
	var gate := rules.gate_at(level, pos, target)
	if not gate.is_empty() and pos.y == gate.row and not rules.can_cross(0, gate.offset, tick):
		state = "fail"
		shake = 1.0
		play_sound(SFX_FAIL)
		return
	if not rules.valid_step(level, pos, target, tick):
		play_sound(SFX_STEP)
		return
	pos = target
	play_sound(SFX_STEP)
	if pos == level.gem and not got_gem:
		got_gem = true
		charge = 1
		play_sound(SFX_WIN)
	if pos == Vector2i(9, 3):
		state = "win"
		if got_gem:
			total_gems += 1
		unlocked = maxi(unlocked, mini(stage + 1, 20))
		save_progress()
		play_sound(SFX_WIN)

func stop_phase() -> void:
	if state == "play" and charge > 0 and freeze_frames == 0:
		charge = 0
		freeze_frames = 60
		held = Vector2i.ZERO
		play_sound(SFX_PULSE)

func play_sound(stream: AudioStream) -> void:
	if not muted:
		audio.stream = stream
		audio.play()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_M and event.pressed:
			muted = not muted
		if event.keycode == KEY_R and event.pressed:
			begin_room(stage)
		if event.keycode == KEY_ENTER and event.pressed:
			activate_main()
		if event.keycode == KEY_SPACE and event.pressed:
			stop_phase()
		var dir := Vector2i.ZERO
		match event.keycode:
			KEY_W, KEY_UP: dir = Vector2i.UP
			KEY_S, KEY_DOWN: dir = Vector2i.DOWN
			KEY_A, KEY_LEFT: dir = Vector2i.LEFT
			KEY_D, KEY_RIGHT: dir = Vector2i.RIGHT
		if dir != Vector2i.ZERO:
			if event.pressed and not event.echo:
				held = dir
				held_repeat = 0.19
				step(dir)
			elif not event.pressed and held == dir:
				held = Vector2i.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			press_at((event.position - ui_origin) / ui_scale)
		else:
			held = Vector2i.ZERO
	if event is InputEventScreenTouch:
		if event.pressed:
			press_at((event.position - ui_origin) / ui_scale)
		else:
			held = Vector2i.ZERO
	if event is InputEventScreenDrag and state == "play":
		var p: Vector2 = (event.position - ui_origin) / ui_scale
		var d := pad_direction(p)
		if d != Vector2i.ZERO:
			held = d

func pad_direction(p: Vector2) -> Vector2i:
	var base := Vector2(70, 875) if portrait else Vector2(792, 479)
	var size := Vector2(76, 76) if portrait else Vector2(60, 58)
	var offset := 76.0 if portrait else 50.0
	var row := 76.0 if portrait else 58.0
	if Rect2(base + Vector2(offset, 0), size).has_point(p): return Vector2i.UP
	if Rect2(base + Vector2(offset, row * 2), size).has_point(p): return Vector2i.DOWN
	if Rect2(base + Vector2(0, row), size).has_point(p): return Vector2i.LEFT
	if Rect2(base + Vector2(offset * 2, row), size).has_point(p): return Vector2i.RIGHT
	return Vector2i.ZERO

func press_at(p: Vector2) -> void:
	if state == "title":
		if (Rect2(55, 790, 450, 86) if portrait else Rect2(310, 487, 340, 67)).has_point(p):
			begin_room(unlocked)
		elif (Rect2(55, 900, 450, 78) if portrait else Rect2(310, 570, 340, 50)).has_point(p):
			begin_room(0)
		return
	if state == "win" or state == "fail":
		activate_main()
		return
	if state != "play": return
	var d := pad_direction(p)
	if d != Vector2i.ZERO:
		held = d
		held_repeat = 0.19
		step(d)
		return
	var stop_rect := Rect2(323, 940, 205, 96) if portrait else Rect2(803, 405, 145, 65)
	if stop_rect.has_point(p):
		stop_phase()
		return
	var restart_rect := Rect2(323, 840, 205, 76) if portrait else Rect2(807, 659, 146, 42)
	if restart_rect.has_point(p):
		begin_room(stage)
		return
	var tile := Vector2i(floori((p.x - board.x) / cell), floori((p.y - board.y) / cell))
	if tile.x >= 0 and tile.x < 11 and tile.y >= 0 and tile.y < 7:
		cursor_target = tile

func activate_main() -> void:
	if state == "title": begin_room(unlocked)
	elif state == "win":
		if stage == 20: state = "title"
		else: begin_room(stage + 1)
	elif state == "fail": begin_room(stage)

func _draw() -> void:
	draw_set_transform(ui_origin, 0.0, Vector2(ui_scale, ui_scale))
	var virtual := Vector2(560, 1210) if portrait else Vector2(960, 720)
	draw_rect(Rect2(Vector2.ZERO, virtual), INK)
	background(virtual)
	if state == "title": draw_title(virtual)
	elif state == "play": draw_game(virtual)
	else: draw_result(virtual)
	draw_set_transform(Vector2.ZERO)

func text(s: String, at: Vector2, size: int, color: Color = LIGHT, align: int = 0) -> void:
	var width := FONT.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var x := at.x - width * (0.5 if align == 1 else (1.0 if align == 2 else 0.0))
	draw_string(FONT, Vector2(x, at.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func background(virtual: Vector2) -> void:
	for i in range(22):
		var y := fmod(float(i * 73) + blink * (2.0 + i % 3), virtual.y)
		var x := fmod(float(i * 233 + 91), virtual.x)
		draw_circle(Vector2(x, y), 1.2 + (i % 3) * 0.6, Color(CYAN, 0.16))
	for i in range(4):
		var r := 150.0 + i * 45
		draw_arc(Vector2(virtual.x * 0.5, virtual.y * 0.52), r, -0.9, 0.9, 48, Color(CYAN, 0.045), 1.0)
	for y in range(0, int(virtual.y), 36):
		draw_line(Vector2(0, y), Vector2(virtual.x, y), Color(CYAN, 0.022), 1.0)

func button(rect: Rect2, label: String, bright: bool = false, available: bool = true, font_size: int = 21) -> void:
	var color := CYAN if bright else Color("25495b")
	if not available: color = Color("587889")
	draw_rect(rect, color, false, 2.0)
	draw_rect(rect.grow(-4), Color(color, 0.20 if available else 0.10))
	text(label, rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.5 + font_size * 0.35), font_size, LIGHT if available else Color("a8bac3"), 1)

func draw_title(virtual: Vector2) -> void:
	var mid := virtual.x * 0.5
	var top := 215.0 if portrait else 110.0
	text("P U L S E   /   B A R R I E R", Vector2(mid, top), 21 if portrait else 17, CYAN, 1)
	text("박동 장벽", Vector2(mid, top + 105), 65 if portrait else 78, LIGHT, 1)
	text("박자가 꺼지는 틈을 건너라", Vector2(mid, top + 156), 27 if portrait else 23, GOLD, 1)
	var cy := top + 285
	for i in range(3):
		var x := mid + (i - 1) * 95
		var c: Color = [GOLD, RED, CYAN][i]
		draw_arc(Vector2(x, cy), 34, 0, TAU, 40, Color(c, 0.5), 3)
		draw_arc(Vector2(x, cy), 25, -PI * 0.5, -PI * 0.5 + TAU * fmod(blink * 0.33 + i * 0.33, 1.0), 36, c, 5)
		text(["예고", "위험", "안전"][i], Vector2(x, cy + 65), 23 if portrait else 19, c, 1)
	var by := 790.0 if portrait else 487.0
	button(Rect2(mid - 225, by, 450, 86) if portrait else Rect2(mid - 170, by, 340, 67), "이어하기  /  시작", true, true, 29 if portrait else 21)
	button(Rect2(mid - 225, by + 110, 450, 78) if portrait else Rect2(mid - 170, by + 83, 340, 50), "처음부터 · 튜토리얼", false, true, 27 if portrait else 21)
	text("방향 패드 / 칸 터치로 이동" if portrait else "방향키 · WASD 이동     SPACE 멈춤", Vector2(mid, by + (236 if portrait else 157)), 25 if portrait else 17, LIGHT, 1)
	text("보석 획득 후 멈춤 사용" if portrait else "터치: 방향 패드 / 칸 터치     M 소리", Vector2(mid, by + (275 if portrait else 183)), 23 if portrait else 15, Color("b7d3da"), 1)
	text("완료 %02d / 21     수집한 빛 %02d" % [unlocked, total_gems], Vector2(mid, by + (326 if portrait else 219)), 21 if portrait else 15, GOLD, 1)

func draw_game(virtual: Vector2) -> void:
	var level: Dictionary = rules.levels[stage]
	text("PULSE  /  %s" % ("튜토리얼" if stage < 3 else "본편"), Vector2(board.x, 65 if portrait else 46), 24 if portrait else 17, CYAN)
	text("%02d  %s" % [stage + 1, level.name], Vector2(board.x, 119 if portrait else 94), 36 if portrait else 30, LIGHT)
	text("켜진 빛은 위험 · 빈틈에서 건너세요" if portrait else "화살표가 가리키는 관문으로 · 켜진 빛은 위험", Vector2(board.x, 164 if portrait else 125), 23 if portrait else 16, Color("c5dce1"))
	if stage < 3:
		text((["01  예고 → 위험 → 안전", "02  다른 박자는 반대로 열립니다", "03  빛을 줍고 멈춤을 사용하세요"][stage] if portrait else ["01  예고 → 위험 → 안전. 빈틈에서 건너세요.", "02  다른 박자는 서로 반대로 열립니다.", "03  빛을 줍고 멈춤으로 한 박 쉬어가세요."][stage]), Vector2(board.x, 208 if portrait else 153), 23 if portrait else 17, GOLD)
	else:
		text("관문 %d개  ·  보석은 선택 목표" % level.gates.size(), Vector2(board.x, 208 if portrait else 153), 23 if portrait else 17, GOLD)
	var bounds := Rect2(board - Vector2(11, 11), Vector2(11, 7) * cell + Vector2(22, 22))
	draw_rect(bounds, Color("0e2636"))
	draw_rect(bounds, Color("3b6972"), false, 2)
	for x in range(11):
		for y in range(7):
			var q := board + Vector2(x, y) * cell
			var shade := Color("143244") if (x + y) % 2 == 0 else Color("183949")
			draw_rect(Rect2(q + Vector2(2, 2), Vector2.ONE * (cell - 4)), shade)
			if (x * 7 + y * 11) % 5 == 0:
				draw_line(q + Vector2(9, cell - 11), q + Vector2(21, cell - 11), Color(CYAN, 0.14), 1)
	for g: Dictionary in level.gates:
		draw_gate(g)
	var gem: Vector2i = level.gem
	if not got_gem:
		var gc := center(gem)
		var pulse := sin(blink * 5.0) * 3.0
		draw_colored_polygon(PackedVector2Array([gc + Vector2(0, -15-pulse), gc + Vector2(13+pulse, 0), gc + Vector2(0, 15+pulse), gc + Vector2(-13-pulse, 0)]), GOLD)
		draw_arc(gc, 21 + pulse, 0, TAU, 32, Color(GOLD, 0.35), 2)
	var goal := center(Vector2i(9, 3))
	draw_arc(goal, cell * 0.37, 0, TAU, 36, CYAN, 3)
	draw_arc(goal, cell * 0.25, blink, blink + 4.5, 30, Color(CYAN, 0.55), 2)
	text("출구", goal + Vector2(0, 6), 16 if portrait else 15, LIGHT, 1)
	var pc := center(pos) + Vector2(shake * sin(blink * 75.0) * 9, 0)
	draw_circle(pc, cell * 0.32, Color(CYAN, 0.14))
	draw_circle(pc, cell * 0.23, CYAN)
	draw_arc(pc, cell * 0.27, -PI * 0.5, PI * 1.5, 28, LIGHT, 2)
	draw_circle(pc, cell * 0.08, INK)
	if portrait:
		draw_portrait_controls()
	else:
		draw_landscape_controls()

func center(tile: Vector2i) -> Vector2:
	return board + (Vector2(tile) + Vector2(0.5, 0.5)) * cell

func draw_gate(g: Dictionary) -> void:
	var x: float = board.x + g.x * cell
	var row: int = g.row
	var phase: int = rules.gate_phase(g.offset, tick)
	var color: Color = [GOLD, RED, CYAN][phase]
	var fraction := fmod(float(tick), 60.0) / 60.0
	for y in range(7):
		var lo := board.y + y * cell + 3
		var hi := lo + cell - 6
		if y != row:
			draw_line(Vector2(x, lo), Vector2(x, hi), Color("35566a"), 8)
			draw_line(Vector2(x, lo), Vector2(x, hi), Color(CYAN, 0.25), 2)
		else:
			var alpha := 0.3 if phase == 2 else (0.65 if phase == 0 else 1.0)
			draw_line(Vector2(x, lo), Vector2(x, hi), Color(color, alpha), 8 if phase == 1 else 3)
			draw_circle(Vector2(x, lo), 6, color)
			draw_circle(Vector2(x, hi), 6, color)
			if phase == 1:
				for z in range(3):
					var yy := lo + 12 + z * 12
					draw_line(Vector2(x-10, yy), Vector2(x+10, yy-5), Color(LIGHT, 0.8), 2)
		draw_line(Vector2(x - 13, board.y - 13), Vector2(x - 13 + fraction * 25, board.y - 13), color, 3)
		text(["!", "×", "○"][phase], Vector2(x, board.y - 23), 17, color, 1)

func draw_landscape_controls() -> void:
	var x := side
	draw_rect(Rect2(x - 12, 175, 171, 532), PANEL)
	text("박동 시계", Vector2(x, 207), 19, LIGHT)
	var p := rules.phase_at(tick)
	text(["01  예고", "02  위험", "03  안전"][p], Vector2(x, 249), 21, [GOLD, RED, CYAN][p])
	for i in range(3):
		var bar := Rect2(x + i * 48, 271, 38, 8)
		draw_rect(bar, [GOLD, RED, CYAN][i] if i == p else Color("31475a"))
	text("빛 %s  /  멈춤 %s" % ["획득" if got_gem else "미획득", "준비" if charge else "없음"], Vector2(x, 333), 16, GOLD)
	button(Rect2(803, 405, 145, 65), "멈춤", true, charge > 0)
	draw_pad(Vector2(792, 479))
	button(Rect2(807, 659, 146, 42), "다시하기")
	text("칸을 누르면 자동 이동", Vector2(board.x, 642), 16, Color("9cb9c2"))
	text("R 재시작   M 소리 끄기", Vector2(board.x, 676), 15, Color("9cb9c2"))

func draw_portrait_controls() -> void:
	var p := rules.phase_at(tick)
	draw_rect(Rect2(20, 674, 520, 139), PANEL)
	text(["01  예고", "02  위험", "03  안전"][p], Vector2(38, 723), 30, [GOLD, RED, CYAN][p])
	text("빛 %s    멈춤 %s" % ["획득" if got_gem else "미획득", "준비" if charge else "없음"], Vector2(38, 774), 25, LIGHT)
	button(Rect2(323, 840, 205, 76), "다시하기", false, true, 26)
	draw_pad(Vector2(70, 875))
	button(Rect2(323, 940, 205, 96), "멈춤", true, charge > 0, 30)
	text("칸 터치로 자동 이동  ·  보석으로 멈춤", Vector2(280, 1164), 22, Color("c5dce1"), 1)

func draw_pad(base: Vector2) -> void:
	var size := Vector2(76, 76) if portrait else Vector2(60, 58)
	var x := 76.0 if portrait else 50.0
	var y := 76.0 if portrait else 58.0
	var font_size := 31 if portrait else 21
	button(Rect2(base + Vector2(x, 0), size), "▲", false, true, font_size)
	button(Rect2(base + Vector2(0, y), size), "◀", false, true, font_size)
	button(Rect2(base + Vector2(x * 2, y), size), "▶", false, true, font_size)
	button(Rect2(base + Vector2(x, y * 2), size), "▼", false, true, font_size)

func draw_result(virtual: Vector2) -> void:
	var mid := virtual.x * 0.5
	var success := state == "win"
	var color := CYAN if success else RED
	var cy := virtual.y * 0.42
	for i in range(5):
		draw_arc(Vector2(mid, cy), 65 + i * 27 + fmod(blink * 16, 26), 0, TAU, 64, Color(color, 0.28 - i * 0.04), 2)
	text("COMPLETE" if success else "SIGNAL LOST", Vector2(mid, cy - 122), 25 if portrait else 19, color, 1)
	text("방을 통과했습니다" if success else "활성 장벽에 닿았습니다", Vector2(mid, cy + 7), 38 if portrait else 43, LIGHT, 1)
	text("%02d  %s" % [stage + 1, rules.levels[stage].name], Vector2(mid, cy + 59), 26 if portrait else 21, GOLD, 1)
	if success:
		text("보석 +1 · 기록 저장" if got_gem else "보석 없이 통과 · 기록 저장", Vector2(mid, cy + 107), 24 if portrait else 18, GOLD, 1)
	else:
		if portrait:
			text("붉은 관문에서는 기다리세요", Vector2(mid, cy + 107), 24, GOLD, 1)
			text("청록색 틈에 이동!", Vector2(mid, cy + 144), 24, GOLD, 1)
		else:
			text("붉은 관문에서는 기다리고, 청록색 틈에 이동", Vector2(mid, cy + 95), 17, GOLD, 1)
	button(Rect2(mid - 225, cy + 204, 450, 94) if portrait else Rect2(mid - 185, cy + 162, 370, 68), "다음 방  ↗" if success and stage < 20 else ("타이틀로" if success else "다시 시도"), true, true, 30 if portrait else 21)
	text("화면 아무 곳이나 터치" if portrait else "ENTER / 화면 아무 곳이나 터치", Vector2(mid, cy + (355 if portrait else 270)), 23 if portrait else 16, Color("c5dce1"), 1)

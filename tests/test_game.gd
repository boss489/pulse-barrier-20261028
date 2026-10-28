extends SceneTree
const Main = preload("res://main.tscn")
func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game = Main.instantiate()
	root.add_child(game)
	game.muted = true
	game.begin_room(0)
	assert(game.state == "play")
	game.pos = Vector2i(4, 1)
	game.tick = 60
	game.step(Vector2i.RIGHT)
	assert(game.state == "fail", "active gate must defeat the player")
	game.activate_main()
	assert(game.state == "play" and game.pos == Vector2i(1, 3))
	game.pos = Vector2i(4, 1)
	game.tick = 120
	game.step(Vector2i.RIGHT)
	assert(game.state == "play" and game.pos == Vector2i(5, 1), "inactive gate is passable")
	game.pos = game.rules.levels[0].gem
	game.got_gem = false
	game.pos = Vector2i(2, 2)
	game.step(Vector2i.UP)
	assert(game.charge == 1)
	game.stop_phase()
	assert(game.charge == 0 and game.freeze_frames == 60)
	game.freeze_frames = 0
	game.pos = Vector2i(9, 2)
	game.step(Vector2i.DOWN)
	assert(game.state == "win" and game.unlocked >= 1)
	var loaded = Main.instantiate()
	root.add_child(loaded)
	assert(loaded.unlocked >= 1 and loaded.total_gems >= 1, "saved progress must reload")
	loaded.free()
	game.activate_main()
	assert(game.state == "play" and game.stage == 1)
	game.free()
	print("PASS scene: active failure, retry, safe crossing, gem, pause, victory, save/reload, progression")
	quit()

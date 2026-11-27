extends Node3D

# This game intentionally contains no generated visual meshes. All visible farm art
# is loaded from redistributable GLB/GLTF assets listed in assets/manifest.json.
const FARM_SCENE_PATH := "res://assets/models/farm/farm_scene.glb"
const SAVE_PATH := "user://farm_save.json"
const PLOT_POSITIONS := [Vector3(-3.0, 0.0, 1.0), Vector3(-1.0, 0.0, 1.0), Vector3(1.0, 0.0, 1.0), Vector3(3.0, 0.0, 1.0)]
const GROW_SECONDS := 45.0

var player: CharacterBody3D
var camera: Camera3D
var hud: Label
var notice: Label
var coins := 25
var seeds := 4
var harvest := 0
var plots: Array[Dictionary] = []
var farm_asset_loaded := false

func _ready() -> void:
	_load_game()
	_load_farm_art()
	_create_player_controller()
	_create_hud()
	for index in PLOT_POSITIONS.size():
		plots.append({"crop": "", "growth": 0.0, "watered": false})
	_update_hud()

func _load_farm_art() -> void:
	if not ResourceLoader.exists(FARM_SCENE_PATH):
		push_warning("Farm scene asset missing: " + FARM_SCENE_PATH)
		return
	var packed := load(FARM_SCENE_PATH) as PackedScene
	if packed == null:
		push_warning("Farm scene is not a valid Godot-importable scene: " + FARM_SCENE_PATH)
		return
	var farm := packed.instantiate()
	farm.name = "FarmArt"
	add_child(farm)
	farm_asset_loaded = true

func _create_player_controller() -> void:
	player = CharacterBody3D.new()
	player.name = "PlayerController"
	player.position = Vector3(0.0, 1.0, 7.0)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.7
	collider.shape = capsule
	collider.position.y = 0.85
	player.add_child(collider)
	add_child(player)

	camera = Camera3D.new()
	camera.name = "FarmCamera"
	camera.position = Vector3(0.0, 7.5, 10.0)
	camera.rotation_degrees.x = -32.0
	camera.current = true
	player.add_child(camera)

func _create_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FarmHUD"
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.position = Vector2(18, 16)
	panel.custom_minimum_size = Vector2(340, 0)
	layer.add_child(panel)
	hud = Label.new()
	hud.add_theme_font_size_override("font_size", 18)
	panel.add_child(hud)
	notice = Label.new()
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(notice)
	if not farm_asset_loaded:
		notice.text = "Не найдена модель фермы. Добавьте farm_scene.glb по инструкции в assets/README.md. Визуальные заглушки не создаются."
		notice.add_theme_color_override("font_color", Color(1.0, 0.76, 0.35))

	var actions := HBoxContainer.new()
	panel.add_child(actions)
	_add_action_button(actions, "Посадить", _plant_nearby)
	_add_action_button(actions, "Полить", _water_nearby)
	_add_action_button(actions, "Собрать", _harvest_nearby)
	_add_action_button(actions, "Продать урожай", _sell_harvest)

func _add_action_button(parent: Control, title: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.pressed.connect(callback)
	parent.add_child(button)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.y += 1.0
	var direction := Vector3(input.x, 0.0, input.y).normalized()
	player.velocity.x = direction.x * 4.0
	player.velocity.z = direction.z * 4.0
	player.velocity.y -= 20.0 * delta
	player.move_and_slide()
	for plot in plots:
		if plot["crop"] != "" and plot["watered"] and plot["growth"] < 1.0:
			plot["growth"] = minf(1.0, plot["growth"] + delta / GROW_SECONDS)

func _nearest_plot_index() -> int:
	var nearest := -1
	var best_distance := 2.8
	for index in PLOT_POSITIONS.size():
		var distance := Vector2(player.position.x, player.position.z).distance_to(Vector2(PLOT_POSITIONS[index].x, PLOT_POSITIONS[index].z))
		if distance < best_distance:
			best_distance = distance
			nearest = index
	return nearest

func _plant_nearby() -> void:
	var index := _nearest_plot_index()
	if index < 0:
		_set_notice("Подойдите к грядке.")
	elif seeds <= 0:
		_set_notice("Семена закончились. Продайте урожай, чтобы заработать монеты.")
	elif plots[index]["crop"] != "":
		_set_notice("Эта грядка уже занята.")
	else:
		seeds -= 1
		plots[index] = {"crop": "Пшеница", "growth": 0.0, "watered": false}
		_set_notice("Пшеница посажена. Полейте грядку, чтобы запустить рост.")
	_update_hud()
	_save_game()

func _water_nearby() -> void:
	var index := _nearest_plot_index()
	if index < 0:
		_set_notice("Подойдите к грядке.")
	elif plots[index]["crop"] == "":
		_set_notice("Сначала посадите семена.")
	elif plots[index]["growth"] >= 1.0:
		_set_notice("Урожай уже созрел.")
	else:
		plots[index]["watered"] = true
		_set_notice("Грядка полита. Урожай созреет примерно за 45 секунд.")
	_update_hud()
	_save_game()

func _harvest_nearby() -> void:
	var index := _nearest_plot_index()
	if index < 0:
		_set_notice("Подойдите к грядке.")
	elif plots[index]["growth"] < 1.0:
		_set_notice("Урожай ещё не созрел. Посадите и полейте грядку.")
	else:
		harvest += 1
		plots[index] = {"crop": "", "growth": 0.0, "watered": false}
		_set_notice("Урожай собран!")
	_update_hud()
	_save_game()

func _sell_harvest() -> void:
	if harvest == 0:
		_set_notice("Пока нечего продавать.")
		return
	coins += harvest * 8
	seeds += harvest
	_set_notice("Урожай продан: +%d монет, получено %d семян." % [harvest * 8, harvest])
	harvest = 0
	_update_hud()
	_save_game()

func _set_notice(text: String) -> void:
	notice.text = text

func _update_hud() -> void:
	if not is_instance_valid(hud):
		return
	var ready_count := 0
	var growing_count := 0
	for plot in plots:
		if plot["growth"] >= 1.0:
			ready_count += 1
		elif plot["crop"] != "":
			growing_count += 1
	hud.text = "ФЕРМА   Монеты: %d   Семена: %d   Урожай: %d\nГрядки: %d растёт · %d готово  |  WASD / стрелки — движение" % [coins, seeds, harvest, growing_count, ready_count]

func _save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"coins": coins, "seeds": seeds, "harvest": harvest, "plots": plots}))

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed := JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	coins = int(parsed.get("coins", coins))
	seeds = int(parsed.get("seeds", seeds))
	harvest = int(parsed.get("harvest", harvest))
	var saved_plots: Array = parsed.get("plots", [])
	for index in min(saved_plots.size(), PLOT_POSITIONS.size()):
		if typeof(saved_plots[index]) == TYPE_DICTIONARY:
			plots.append(saved_plots[index])

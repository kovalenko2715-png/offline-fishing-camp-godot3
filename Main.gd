extends Node3D

const SAVE_PATH := "user://save.json"

var wood := 0
var stone := 0
var fish := 0
var coins := 50
var hp := 100
var warmth := 100
var completed_quest := false
var joy := Vector2.ZERO

var joystick: Control
var stick: Label
var quest_label: Label
var stats_label: Label
var player: CharacterBody3D

func _ready() -> void:
	load_save()
	create_world()
	create_player()
	create_mobile_ui()

func create_box(size: Vector3, position: Vector3, color: Color, parent: Node = self) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.position = position
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance

func create_world() -> void:
	create_box(Vector3(30, 0.3, 30), Vector3(0, -0.15, 0), Color("488a3d"))
	create_box(Vector3(14, 0.2, 10), Vector3(0, 0.02, -10), Color("2a879a"))
	create_box(Vector3(15, 0.06, 2), Vector3(0, 0.14, -4.5), Color("c9b27b"))

	create_box(Vector3(4, 2.2, 3), Vector3(-7, 1.1, 4), Color("8d3228"))
	create_box(Vector3(4.4, 0.25, 3.4), Vector3(-7, 2.35, 4), Color("3d2922"))

	create_box(Vector3(2.6, 0.14, 1.2), Vector3(-2, 1.15, 4), Color("70472e"))
	create_box(Vector3(0.16, 1.1, 0.16), Vector3(-3, 0.55, 4), Color("4d321f"))
	create_box(Vector3(0.16, 1.1, 0.16), Vector3(-1, 0.55, 4), Color("4d321f"))

	create_box(Vector3(1.4, 0.08, 1.4), Vector3(3.5, 0.12, 4), Color("4b2a1c"))
	create_box(Vector3(0.4, 1.1, 0.4), Vector3(3.5, 0.7, 4), Color("e96b27"))

	create_box(Vector3(4.6, 3.2, 3.8), Vector3(7.5, 1.6, 5), Color("987b50"))
	create_box(Vector3(5.2, 0.25, 4.4), Vector3(7.5, 3.3, 5), Color("33291f"))

	for i in range(12):
		var x := -13.0 + i * 2.4
		create_box(Vector3(0.45, 2.4, 0.45), Vector3(x, 1.2, 9), Color("5a3822"))
		create_box(Vector3(2.2, 2.2, 2.2), Vector3(x, 3.2, 9), Color("225c28"))

	for i in range(6):
		var stone_node := create_box(Vector3(1.0, 0.7, 0.8), Vector3(-10 + i * 4.0, 0.35, -7), Color("777a78"))
		stone_node.name = "ResourceStone"

func create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1.2, 7)
	add_child(player)

	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.45
	mesh.height = 1.8
	body.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("3e78b5")
	body.material_override = material
	body.position.y = 0.9
	player.add_child(body)

	var camera := Camera3D.new()
	camera.current = true
	camera.position = Vector3(0, 6.5, 10)
	camera.rotation_degrees.x = -32
	player.add_child(camera)

func create_mobile_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	stats_label = Label.new()
	stats_label.position = Vector2(30, 20)
	stats_label.scale = Vector2(1.3, 1.3)
	canvas.add_child(stats_label)

	quest_label = Label.new()
	quest_label.position = Vector2(30, 56)
	quest_label.scale = Vector2(1.25, 1.25)
	canvas.add_child(quest_label)

	var gather_button := Button.new()
	gather_button.text = "Собрать"
	gather_button.position = Vector2(820, 420)
	gather_button.size = Vector2(180, 65)
	gather_button.pressed.connect(_on_gather_pressed)
	canvas.add_child(gather_button)

	var interact_button := Button.new()
	interact_button.text = "Лагерь / Магазин"
	interact_button.position = Vector2(820, 500)
	interact_button.size = Vector2(180, 65)
	interact_button.pressed.connect(_on_interact_pressed)
	canvas.add_child(interact_button)

	joystick = Control.new()
	joystick.position = Vector2(30, 430)
	joystick.size = Vector2(200, 150)
	joystick.gui_input.connect(_on_joystick_input)
	canvas.add_child(joystick)

	stick = Label.new()
	stick.text = "●"
	stick.position = Vector2(85, 55)
	stick.scale = Vector2(3, 3)
	stick.modulate = Color(1, 1, 1, 0.65)
	joystick.add_child(stick)

	update_ui()

func update_ui() -> void:
	stats_label.text = "HP %d  Тепло %d  Дерево %d  Камень %d  Рыба %d  Монет %d" % [hp, warmth, wood, stone, fish, coins]
	quest_label.text = "Квест: собери дерево 5/5 и камень 3/3" if not completed_quest else "Квест выполнен — получи награду у лагеря"

func _physics_process(delta: float) -> void:
	if not player:
		return
	var direction := Vector3(joy.x, 0, joy.y)
	if direction.length() > 0.1:
		player.velocity = direction.normalized() * 4.0
		player.move_and_slide()
		player.position.x = clamp(player.position.x, -13.0, 13.0)
		player.position.z = clamp(player.position.z, -4.0, 12.0)

func _on_joystick_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag or event is InputEventScreenTouch:
		var relative := event.position - joystick.position - Vector2(100, 75)
		if event is InputEventScreenTouch and not event.pressed:
			relative = Vector2.ZERO
		joy = relative.limit_length(55.0) / 55.0
		stick.position = Vector2(85 + joy.x * 25, 55 + joy.y * 25)

func _on_gather_pressed() -> void:
	var distance_to_stones := INF
	for node in get_children():
		if node is MeshInstance3D and node.name == "ResourceStone":
			distance_to_stones = min(distance_to_stones, player.position.distance_to(node.position))
	if distance_to_stones < 5.0:
		stone += 1
	else:
		wood += 1
	if wood >= 5 and stone >= 3:
		completed_quest = true
	update_ui()
	save_game()

func _on_interact_pressed() -> void:
	if player.position.distance_to(Vector3(-7, 1.2, 4)) < 5:
		warmth = 100
		wood = max(0, wood - 1)
	elif player.position.distance_to(Vector3(7.5, 1.2, 5)) < 5:
		if coins >= 10:
			coins -= 10
			fish += 1
	else:
		quest_label.text = "Подойдите к палатке или магазину"
		return
	if completed_quest:
		completed_quest = false
		coins += 50
	update_ui()
	save_game()

func save_game() -> void:
	var data := {"wood": wood, "stone": stone, "fish": fish, "coins": coins, "hp": hp, "warmth": warmth, "completed_quest": completed_quest}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed := JSON.new()
	if parsed.parse(file.get_as_text()) != OK:
		return
	var data: Dictionary = parsed.data
	wood = int(data.get("wood", 0))
	stone = int(data.get("stone", 0))
	fish = int(data.get("fish", 0))
	coins = int(data.get("coins", 50))
	hp = int(data.get("hp", 100))
	warmth = int(data.get("warmth", 100))
	completed_quest = bool(data.get("completed_quest", false))

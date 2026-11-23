extends Spatial

var caught := 0
var coins := 0
var casting := false
var joy_vector := Vector2.ZERO
var fish_nodes := []
var ui
var joystick
var stick

func _ready():
	setup_world()
	setup_player()
	setup_ui()
	for i in range(9):
		spawn_fish(Vector3(rand_range(-8, 8), 0.45, rand_range(-10, -3)))

func box(name: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance:
	var m = MeshInstance.new()
	m.name = name
	var mesh = CubeMesh.new()
	mesh.size = size
	m.mesh = mesh
	var mat = SpatialMaterial.new()
	mat.albedo_color = color
	m.material_override = mat
	m.translation = pos
	add_child(m)
	return m

func setup_world():
	box("Grass", Vector3(30, 0.3, 24), Vector3(0, -0.15, 0), Color(0.28, 0.50, 0.22))
	box("Lake", Vector3(18, 0.12, 10), Vector3(0, 0.02, -11), Color(0.12, 0.48, 0.63))
	box("Sand", Vector3(18.5, 0.08, 2.2), Vector3(0, 0.09, -5.2), Color(0.72, 0.62, 0.40))

	var tent = box("Tent", Vector3(3.5, 2.2, 3.0), Vector3(-7, 1.1, 5), Color(0.72, 0.25, 0.16))
	tent.rotation_degrees.y = 35

	box("TableTop", Vector3(2.5, 0.16, 1.1), Vector3(-2.2, 1.05, 5), Color(0.48, 0.29, 0.15))
	box("TableLeg1", Vector3(0.14, 1.0, 0.14), Vector3(-3.1, 0.5, 5), Color(0.35, 0.20, 0.10))
	box("TableLeg2", Vector3(0.14, 1.0, 0.14), Vector3(-1.3, 0.5, 5), Color(0.35, 0.20, 0.10))

	box("Campfire", Vector3(1.2, 0.08, 1.2), Vector3(3.5, 0.22, 5), Color(0.25, 0.10, 0.05))
	box("Flame", Vector3(0.35, 1.0, 0.35), Vector3(3.5, 0.75, 5), Color(1.0, 0.42, 0.06))
	box("Shop", Vector3(4.5, 3.0, 3.5), Vector3(7.5, 1.5, 6), Color(0.58, 0.43, 0.25))
	box("ShopRoof", Vector3(5.2, 0.25, 4.2), Vector3(7.5, 3.15, 6), Color(0.18, 0.16, 0.12))
	box("RodRack", Vector3(0.15, 2.2, 2.0), Vector3(5.2, 1.1, 4.3), Color(0.35, 0.20, 0.10))

	for i in range(14):
		var x = -13 + i * 2
		box("TreeTrunk", Vector3(0.45, 2.2, 0.45), Vector3(x, 1.1, 10), Color(0.30, 0.18, 0.09))
		box("TreeCrown", Vector3(2.0, 2.0, 2.0), Vector3(x, 3.0, 10), Color(0.12, 0.36, 0.14))

func setup_player():
	var body = KinematicBody.new()
	body.name = "Player"
	body.translation = Vector3(0, 1.2, 7)
	add_child(body)
	var mesh = MeshInstance.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.45
	capsule.mid_height = 1.0
	mesh.mesh = capsule
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(0.18, 0.42, 0.75)
	mesh.material_override = mat
	mesh.translation.y = 0.9
	body.add_child(mesh)
	var camera = Camera.new()
	camera.current = true
	camera.translation = Vector3(0, 6.5, 10)
	camera.rotation_degrees.x = -32
	body.add_child(camera)

func setup_ui():
	ui = CanvasLayer.new()
	add_child(ui)
	var title = Label.new()
	title.text = "Рыбалка у озера"
	title.rect_position = Vector2(30, 20)
	title.rect_scale = Vector2(1.5, 1.5)
	ui.add_child(title)
	var stats = Label.new()
	stats.name = "Stats"
	stats.text = stats_text()
	stats.rect_position = Vector2(30, 52)
	stats.rect_scale = Vector2(1.3, 1.3)
	ui.add_child(stats)
	var cast = Button.new()
	cast.name = "Cast"
	cast.text = "Забросить"
	cast.rect_position = Vector2(820, 520)
	cast.rect_size = Vector2(180, 70)
	cast.connect("pressed", self, "_cast")
	ui.add_child(cast)
	var shop = Button.new()
	shop.name = "Shop"
	shop.text = "Магазин"
	shop.rect_position = Vector2(820, 430)
	shop.rect_size = Vector2(180, 70)
	shop.connect("pressed", self, "_shop")
	ui.add_child(shop)
	joystick = Control.new()
	joystick.name = "Joystick"
	joystick.rect_position = Vector2(30, 420)
	joystick.rect_size = Vector2(200, 160)
	joystick.connect("gui_input", self, "_joystick_input")
	ui.add_child(joystick)
	stick = Label.new()
	stick.text = "●"
	stick.rect_position = Vector2(82, 55)
	stick.rect_scale = Vector2(3, 3)
	stick.modulate = Color(1, 1, 1, 0.7)
	joystick.add_child(stick)

func stats_text():
	return "Поймано: %d  Монет: %d" % [caught, coins]

func update_stats():
	ui.get_node("Stats").text = stats_text()

func spawn_fish(pos: Vector3):
	var fish = Spatial.new()
	fish.name = "Fish"
	fish.translation = pos
	add_child(fish)
	var body = MeshInstance.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.7
	body.mesh = sphere
	body.scale = Vector3(1.5, 0.7, 0.7)
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(rand_range(0.55, 1.0), rand_range(0.20, 0.55), rand_range(0.05, 0.25))
	body.material_override = mat
	fish.add_child(body)
	fish_nodes.append(fish)

func _physics_process(delta):
	var player = get_node("Player")
	var movement = Vector3(joy_vector.x, 0, joy_vector.y)
	if movement.length() > 0.1:
		player.translation += movement * 4.0 * delta
		player.translation.x = clamp(player.translation.x, -13, 13)
		player.translation.z = clamp(player.translation.z, -4.5, 11)
	for fish in fish_nodes:
		fish.translation.x += sin(OS.get_ticks_msec() * 0.001 + fish.translation.z) * delta * 0.45
		if fish.translation.x > 9: fish.translation.x = -9
		if fish.translation.x < -9: fish.translation.x = 9

func _joystick_input(event):
	if event is InputEventScreenDrag or event is InputEventScreenTouch:
		var rel = event.position - joystick.rect_position - Vector2(100, 80)
		if event is InputEventScreenTouch and not event.pressed:
			rel = Vector2.ZERO
		joy_vector = rel.clamped(55) / 55.0
		stick.rect_position = Vector2(82 + joy_vector.x * 25, 55 + joy_vector.y * 25)

func _cast():
	if casting:
		return
	var player = get_node("Player")
	var btn = ui.get_node("Cast")
	if player.translation.z > -4.0:
		btn.text = "Подойдите к берегу"
		return
	casting = true
	btn.text = "Подсечка!"
	caught += 1
	coins += 5
	update_stats()
	btn.text = "Забросить"
	casting = false

func _shop():
	var player = get_node("Player")
	var btn = ui.get_node("Shop")
	if player.translation.distance_to(Vector3(7.5, 1.2, 6)) < 4:
		btn.text = "Есть: удочка x1"
	else:
		btn.text = "Подойдите к магазину"

extends Spatial

const ASSET_MANIFEST := "res://assets/manifest.json"

func try_load_model(path: String, name: String) -> Spatial:
	if not ResourceLoader.exists(path):
		return null
	var packed = load(path)
	if packed == null:
		push_warning("Не удалось загрузить модель: " + path)
		return null
	var instance = packed.instance() as Spatial
	if instance:
		instance.name = name
		return instance
	return null

func add_model_if_available(path: String, name: String, position: Vector3, scale: Vector3 = Vector3.ONE) -> Spatial:
	var model = try_load_model(path, name)
	if model:
		model.translation = position
		model.scale = scale
		add_child(model)
	return model

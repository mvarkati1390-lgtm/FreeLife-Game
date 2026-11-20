extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
var player: CharacterBody3D
var hud: CanvasLayer
var message_label: Label
var cash := 5000
var current_job := "بیکار"
var car_node: Node3D
var in_car := false

func _ready():
    _build_world()
    _build_player()
    _build_car()
    _build_hud()

func _mat(color: Color, roughness := 1.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    return m

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, node_name := "Block") -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    mi.mesh = mesh
    mi.position = pos
    mi.material_override = _mat(color)
    parent.add_child(mi)
    return mi

func _build_world():
    _box(self, Vector3(0,-0.6,0), Vector3(260,1,260), Color("#66875a"), "Grass")
    _box(self, Vector3(0,-0.02,0), Vector3(260,0.12,18), Color("#343b40"), "MainRoad")
    _box(self, Vector3(0,0.0,0), Vector3(18,0.13,260), Color("#343b40"), "CrossRoad")
    for i in range(-120,121,16):
        _box(self, Vector3(i,0.08,0), Vector3(7,0.025,0.22), Color("#e6d7a0"), "RoadMark")
        _box(self, Vector3(0,0.08,i), Vector3(0.22,0.025,7), Color("#e6d7a0"), "RoadMark")
    for side in [-1,1]:
        _box(self, Vector3(0,0.03,side*11), Vector3(260,0.25,3), Color("#aaa99b"), "Sidewalk")
        _box(self, Vector3(side*11,0.03,0), Vector3(3,0.25,260), Color("#aaa99b"), "Sidewalk")
    var rng := RandomNumberGenerator.new()
    rng.seed = 1402
    var palette = [Color("#c7a47b"), Color("#d4c2a0"), Color("#9d9c86"), Color("#b77d63"), Color("#d0b77f")]
    for x in range(-5,6):
        for z in range(-5,6):
            if abs(x) <= 1 or abs(z) <= 1:
                continue
            var h := rng.randf_range(5.0, 13.0)
            var w := rng.randf_range(9.0, 15.0)
            var d := rng.randf_range(9.0, 15.0)
            var px := x*24.0 + rng.randf_range(-2,2)
            var pz := z*24.0 + rng.randf_range(-2,2)
            _box(self, Vector3(px,h/2,pz), Vector3(w,h,d), palette[rng.randi_range(0,palette.size()-1)], "Building")
            _box(self, Vector3(px,h+0.35,pz), Vector3(w+0.3,0.7,d+0.3), Color("#5b5149"), "Roof")
            for wx in [-0.3,0.3]:
                _box(self, Vector3(px+wx*w, h*0.55, pz-d/2-0.03), Vector3(1.3,1.4,0.08), Color("#577b8b"), "Window")
    _add_location("شهرداری", Vector3(-31,0,0), Color("#d9b85f"))
    _add_location("تعمیرگاه", Vector3(31,0,0), Color("#d18a54"))
    _add_location("بانک", Vector3(0,0,-31), Color("#e5d48d"))
    _add_location("خانه", Vector3(0,0,31), Color("#b99ad5"))
    _add_trees()

func _add_location(label_text: String, pos: Vector3, color: Color):
    var root := Node3D.new()
    root.position = pos
    add_child(root)
    _box(root, Vector3(0,1.8,0), Vector3(8,3.6,7), color, "Building")
    _box(root, Vector3(0,3.9,0), Vector3(8.5,0.6,7.5), Color("#514a43"), "Roof")
    var label := Label3D.new()
    label.text = label_text
    label.position = Vector3(0,5.2,0)
    label.font_size = 48
    label.modulate = Color("#fff6d8")
    root.add_child(label)
    root.set_meta("place_name", label_text)

func _add_trees():
    for p in [Vector3(-48,0,-35),Vector3(48,0,35),Vector3(-50,0,45),Vector3(50,0,-45),Vector3(-34,0,55),Vector3(34,0,-55)]:
        _box(self,p+Vector3(0,1.4,0),Vector3(0.8,2.8,0.8),Color("#73523a"),"TreeTrunk")
        var crown := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = 2.5
        sphere.height = 5
        crown.mesh = sphere
        crown.position = p+Vector3(0,4,0)
        crown.material_override = _mat(Color("#47764a"))
        add_child(crown)

func _build_player():
    player = CharacterBody3D.new()
    player.name = "Player"
    player.set_script(PLAYER_SCRIPT)
    add_child(player)
    player.position = Vector3(0,1,4)
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.48
    capsule.height = 1.9
    body.mesh = capsule
    body.material_override = _mat(Color("#d5c7a8"))
    player.add_child(body)
    var shape := CollisionShape3D.new()
    var cs := CapsuleShape3D.new()
    cs.radius = 0.48
    cs.height = 1.9
    shape.shape = cs
    player.add_child(shape)
    var cam := Camera3D.new()
    cam.position = Vector3(0,5.5,9)
    cam.rotation_degrees = Vector3(-24,0,0)
    cam.current = true
    player.add_child(cam)

func _build_car():
    car_node = Node3D.new()
    car_node.position = Vector3(7,0.8,5)
    add_child(car_node)
    _box(car_node,Vector3(0,0.5,0),Vector3(4.2,1.0,2.0),Color("#b64b3e"),"CarBody")
    _box(car_node,Vector3(-0.2,1.25,0),Vector3(2.2,0.8,1.7),Color("#8faeb9"),"CarCabin")
    for x in [-1.3,1.3]:
        for z in [-1.05,1.05]:
            var wheel := MeshInstance3D.new()
            var cyl := CylinderMesh.new()
            cyl.top_radius = 0.42
            cyl.bottom_radius = 0.42
            cyl.height = 0.25
            wheel.mesh = cyl
            wheel.rotation_degrees.z = 90
            wheel.position = Vector3(x,0.25,z)
            wheel.material_override = _mat(Color("#202326"))
            car_node.add_child(wheel)

func _build_hud():
    hud = CanvasLayer.new()
    add_child(hud)
    var panel := PanelContainer.new()
    panel.position = Vector2(14,14)
    panel.custom_minimum_size = Vector2(250,90)
    hud.add_child(panel)
    var vb := VBoxContainer.new()
    panel.add_child(vb)
    var title := Label.new()
    title.text = "ArSaCiA RolePlay | آفلاین"
    vb.add_child(title)
    message_label = Label.new()
    message_label.text = "به شهرداری برو و شغل انتخاب کن."
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vb.add_child(message_label)
    var cash_label := Label.new()
    cash_label.name = "CashLabel"
    cash_label.text = "پول: $5,000  |  شغل: بیکار"
    vb.add_child(cash_label)
    var buttons := HBoxContainer.new()
    buttons.position = Vector2(14,620)
    hud.add_child(buttons)
    var directions = [["▲","up"],["◀","left"],["▼","down"],["▶","right"]]
    for pair in directions:
        var b := Button.new()
        b.text = pair[0]
        b.custom_minimum_size = Vector2(64,64)
        var direction: String = pair[1]
        b.pressed.connect(func(): player.call("move_mobile", direction))
        buttons.add_child(b)
    var actions := VBoxContainer.new()
    actions.position = Vector2(1040,570)
    hud.add_child(actions)
    var interact := Button.new()
    interact.text = "تعامل"
    interact.custom_minimum_size = Vector2(150,55)
    interact.pressed.connect(_interact)
    actions.add_child(interact)
    var car_btn := Button.new()
    car_btn.text = "سوار / پیاده"
    car_btn.custom_minimum_size = Vector2(150,55)
    car_btn.pressed.connect(_toggle_car)
    actions.add_child(car_btn)
    var job_btn := Button.new()
    job_btn.text = "شغل: راننده تاکسی"
    job_btn.custom_minimum_size = Vector2(150,55)
    job_btn.pressed.connect(func():
        current_job = "راننده تاکسی"
        _refresh_hud()
        message_label.text = "شغل انتخاب شد؛ به ایستگاه برو."
    )
    actions.add_child(job_btn)
    var save_btn := Button.new()
    save_btn.text = "ذخیره"
    save_btn.custom_minimum_size = Vector2(150,55)
    save_btn.pressed.connect(_save_game)
    actions.add_child(save_btn)

func _refresh_hud():
    var label = hud.find_child("CashLabel", true, false)
    if label:
        label.text = "پول: $%s  |  شغل: %s" % [cash, current_job]

func _interact():
    var nearest_name := ""
    var nearest_dist := 99999.0
    for n in get_children():
        if n.has_meta("place_name"):
            var d = player.global_position.distance_to(n.global_position)
            if d < nearest_dist:
                nearest_dist = d
                nearest_name = str(n.get_meta("place_name"))
    if nearest_dist > 12:
        message_label.text = "به مکان موردنظر نزدیک‌تر شو."
    elif nearest_name == "بانک":
        cash += 250
        message_label.text = "تراکنش آزمایشی بانک: ۲۵۰ دلار اضافه شد."
    elif nearest_name == "شهرداری":
        current_job = "راننده تاکسی"
        message_label.text = "در شهرداری شغل راننده تاکسی را انتخاب کردی."
    elif nearest_name == "تعمیرگاه":
        cash = max(0, cash - 100)
        message_label.text = "ماشین تعمیر شد؛ هزینه ۱۰۰ دلار."
    elif nearest_name == "خانه":
        message_label.text = "خانه فعلاً قابل بازدید است؛ خرید خانه در مرحله بعد."
    _refresh_hud()

func _toggle_car():
    if player.global_position.distance_to(car_node.global_position) < 8:
        in_car = !in_car
        message_label.text = "سوار ماشین شدی." if in_car else "از ماشین پیاده شدی."
    else:
        message_label.text = "به ماشین قرمز نزدیک شو."

func _save_game():
    var f = FileAccess.open("user://savegame.json", FileAccess.WRITE)
    f.store_string(JSON.stringify({"cash":cash,"job":current_job,"player":[player.position.x,player.position.y,player.position.z]}))
    message_label.text = "بازی ذخیره شد."

func _process(_delta):
    if in_car and player:
        car_node.global_position = player.global_position + Vector3(0,-0.2,0)

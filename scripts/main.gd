extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
var player: CharacterBody3D
var hud: CanvasLayer
var message_label: Label
var cash := 5000
var current_job := "بیکار"
var car_node: Node3D
var in_car := false
var house_owned := false
var mission_active := false
var mission_marker: MeshInstance3D
var mission_target := Vector3(82, 0, -78)
var mission_reward := 750
var job_index := 0
const JOBS := ["راننده تاکسی", "راننده اتوبوس", "راننده کامیون", "کشاورز", "خبرنگار", "مکانیک", "معلم"]
const JOB_TARGETS := [Vector3(82,0,-78), Vector3(-92,0,72), Vector3(105,0,96), Vector3(-100,0,-90), Vector3(0,0,-112), Vector3(112,0,-15), Vector3(-20,0,112)]
const JOB_REWARDS := [750, 900, 1200, 650, 700, 800, 700]
var game_minutes := 8 * 60
var save_path := "user://arsacia_save.json"

func _ready():
    _build_world()
    _build_player()
    _build_car()
    _build_hud()
    _load_game()
    _refresh_hud()

func _process(delta):
    game_minutes = (game_minutes + int(delta * 2.0)) % (24 * 60)
    if in_car and player and car_node:
        car_node.global_position = player.global_position + Vector3(0,-0.15,0)
        car_node.rotation.y = player.rotation.y
    if mission_active and player:
        var actor_pos = player.global_position
        if actor_pos.distance_to(mission_target) < 8.0:
            mission_active = false
            cash += mission_reward
            mission_marker.visible = false
            message_label.text = "مأموریت %s انجام شد! %s دلار پاداش گرفتی." % [current_job, mission_reward]
            _refresh_hud()
    var clock = hud.find_child("ClockLabel", true, false) if hud else null
    if clock:
        clock.text = "ساعت %02d:%02d" % [int(game_minutes / 60), game_minutes % 60]

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
    _box(self, Vector3(0,-0.6,0), Vector3(280,1,280), Color("#66875a"), "Grass")
    # Main avenues and cross streets
    for road_index in range(-5,6):
        var offset = road_index * 24.0
        _box(self, Vector3(offset,0,0), Vector3(11,0.14,280), Color("#343b40"), "Street")
        _box(self, Vector3(0,0,offset), Vector3(280,0.14,11), Color("#343b40"), "Street")
        for mark in range(-6,7):
            _box(self, Vector3(offset,0.09,mark*20), Vector3(0.18,0.025,4.5), Color("#e6d7a0"), "LaneMark")
            _box(self, Vector3(mark*20,0.09,offset), Vector3(4.5,0.025,0.18), Color("#e6d7a0"), "LaneMark")
    var rng := RandomNumberGenerator.new()
    rng.seed = 1402
    var palette = [Color("#c7a47b"), Color("#d4c2a0"), Color("#9d9c86"), Color("#b77d63"), Color("#d0b77f")]
    for x in range(-5,6):
        for z in range(-5,6):
            if abs(x) <= 1 or abs(z) <= 1:
                continue
            var h := rng.randf_range(5.0, 16.0)
            var w := rng.randf_range(9.0, 15.0)
            var d := rng.randf_range(9.0, 15.0)
            var px := x*24.0 + rng.randf_range(-2,2)
            var pz := z*24.0 + rng.randf_range(-2,2)
            _box(self, Vector3(px,h/2,pz), Vector3(w,h,d), palette[rng.randi_range(0,palette.size()-1)], "Building")
            _box(self, Vector3(px,h+0.35,pz), Vector3(w+0.3,0.7,d+0.3), Color("#5b5149"), "Roof")
            for wx in [-0.3,0.3]:
                _box(self, Vector3(px+wx*w, h*0.55, pz-d/2-0.03), Vector3(1.3,1.4,0.08), Color("#577b8b"), "Window")
    _add_location("شهرداری و کاریابی", Vector3(-31,0,0), Color("#d9b85f"))
    _add_location("تعمیرگاه", Vector3(31,0,0), Color("#d18a54"))
    _add_location("بانک", Vector3(0,0,-31), Color("#e5d48d"))
    _add_location("خانه فروشی", Vector3(0,0,31), Color("#b99ad5"))
    _add_location("مرکز شهر - Los Santos", Vector3(0,0,0), Color("#5c9c9b"))
    _add_location("منطقه ساحلی", Vector3(-96,0,0), Color("#6b9da5"))
    _add_location("منطقه صنعتی", Vector3(96,0,0), Color("#9b8068"))
    _add_location("منطقه کوهستانی", Vector3(0,0,96), Color("#71865a"))
    _add_location("منطقه تجاری", Vector3(0,0,-96), Color("#b7a06e"))
    _add_location("ایستگاه اتوبوس", Vector3(-31,0,31), Color("#6595b0"))
    _add_location("خبرگزاری", Vector3(31,0,-31), Color("#a58cba"))
    _add_location("مدرسه", Vector3(31,0,31), Color("#86a77b"))
    _add_location("مزرعه", Vector3(-31,0,-31), Color("#8ca85e"))
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
    label.font_size = 40
    label.modulate = Color("#fff6d8")
    root.add_child(label)
    root.set_meta("place_name", label_text)

func _add_trees():
    for p in [Vector3(-48,0,-35),Vector3(48,0,35),Vector3(-50,0,45),Vector3(50,0,-45),Vector3(-34,0,55),Vector3(34,0,-55),Vector3(70,0,40),Vector3(-70,0,-40)]:
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
    body.name = "PlayerVisual"
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
    cam.position = Vector3(0,6.5,11)
    cam.rotation_degrees = Vector3(-25,0,0)
    cam.current = true
    player.add_child(cam)

func _build_car():
    car_node = Node3D.new()
    car_node.name = "PlayerCar"
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
    panel.custom_minimum_size = Vector2(280,118)
    hud.add_child(panel)
    var vb := VBoxContainer.new()
    panel.add_child(vb)
    var title := Label.new()
    title.text = "ArSaCiA RolePlay | شهر آفلاین"
    vb.add_child(title)
    message_label = Label.new()
    message_label.text = "به شهر خوش آمدی؛ از کاریابی شغل بگیر."
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vb.add_child(message_label)
    var cash_label := Label.new()
    cash_label.name = "CashLabel"
    vb.add_child(cash_label)
    var clock := Label.new()
    clock.name = "ClockLabel"
    vb.add_child(clock)
    var directions := [["▲","up"],["◀","left"],["▼","down"],["▶","right"]]
    var move_box := HBoxContainer.new()
    move_box.position = Vector2(16,570)
    hud.add_child(move_box)
    for pair in directions:
        var b := Button.new()
        b.text = pair[0]
        b.custom_minimum_size = Vector2(66,66)
        var direction: String = pair[1]
        b.button_down.connect(func(): player.call("set_mobile_direction", direction, true))
        b.button_up.connect(func(): player.call("set_mobile_direction", direction, false))
        move_box.add_child(b)
    var actions := VBoxContainer.new()
    actions.position = Vector2(1040,450)
    hud.add_child(actions)
    _action_button(actions,"تعامل",_interact)
    _action_button(actions,"سوار / پیاده",_toggle_car)
    _action_button(actions,"شروع مأموریت",_start_mission)
    _action_button(actions,"خانه",_buy_or_visit_house)
    _action_button(actions,"ذخیره",_save_game)

func _action_button(parent: VBoxContainer, text_value: String, callback: Callable):
    var b := Button.new()
    b.text = text_value
    b.custom_minimum_size = Vector2(190,54)
    b.pressed.connect(callback)
    parent.add_child(b)

func _refresh_hud():
    if not hud: return
    var label = hud.find_child("CashLabel", true, false)
    if label:
        label.text = "پول: $%s | شغل: %s | خانه: %s" % [cash, current_job, "خریده‌شده" if house_owned else "نداری"]

func _interact():
    var nearest_name := ""
    var nearest_dist := 99999.0
    for n in get_children():
        if n.has_meta("place_name"):
            var d = player.global_position.distance_to(n.global_position)
            if d < nearest_dist:
                nearest_dist = d
                nearest_name = str(n.get_meta("place_name"))
    if nearest_dist > 14:
        message_label.text = "برای تعامل به یکی از ساختمان‌های علامت‌دار نزدیک شو."
    elif nearest_name == "بانک":
        cash += 250
        message_label.text = "واریز آزمایشی انجام شد؛ ۲۵۰ دلار پاداش."
    elif nearest_name == "شهرداری و کاریابی":
        job_index = (job_index + 1) % JOBS.size()
        current_job = JOBS[job_index]
        message_label.text = "شغل جدید: %s. برای دریافت کار، شروع مأموریت را بزن." % current_job
    elif nearest_name == "ایستگاه اتوبوس":
        current_job = "راننده اتوبوس"
        message_label.text = "شغل راننده اتوبوس انتخاب شد. مأموریت بگیر."
    elif nearest_name == "خبرگزاری":
        current_job = "خبرنگار"
        message_label.text = "شغل خبرنگار انتخاب شد. مأموریت بگیر."
    elif nearest_name == "مدرسه":
        current_job = "معلم"
        message_label.text = "شغل معلم انتخاب شد. مأموریت بگیر."
    elif nearest_name == "مزرعه":
        current_job = "کشاورز"
        message_label.text = "شغل کشاورز انتخاب شد. مأموریت بگیر."
    elif nearest_name == "تعمیرگاه":
        cash = max(0, cash - 100)
        message_label.text = "ماشین سرویس شد؛ ۱۰۰ دلار هزینه."
    elif nearest_name == "خانه فروشی":
        _buy_or_visit_house()
    else:
        message_label.text = "به مرکز شهر رسیدی."
    _refresh_hud()

func _toggle_car():
    if player.global_position.distance_to(car_node.global_position) < 9:
        in_car = !in_car
        var visual = player.get_node_or_null("PlayerVisual")
        if visual: visual.visible = not in_car
        player.set("speed", 15.0 if in_car else 7.0)
        message_label.text = "سوار ماشین شدی؛ با دکمه‌های جهت حرکت کن." if in_car else "از ماشین پیاده شدی."
    else:
        message_label.text = "برای سوار شدن به ماشین قرمز نزدیک شو."

func _start_mission():
    if current_job == "بیکار":
        message_label.text = "اول از شهرداری شغل بگیر."
        return
    if mission_active:
        message_label.text = "مأموریت فعال است؛ به نشان زرد روی نقشه برو."
        return
    mission_active = true
    var idx := JOBS.find(current_job)
    if idx < 0: idx = 0
    mission_target = JOB_TARGETS[idx]
    mission_reward = JOB_REWARDS[idx]
    if mission_marker and is_instance_valid(mission_marker):
        mission_marker.queue_free()
    mission_marker = _box(self, mission_target + Vector3(0,1.2,0), Vector3(3,2.4,3), Color("#f2d23b"), "MissionDestination")
    message_label.text = "مأموریت %s شروع شد؛ به نشان زرد برو. پاداش: %s دلار." % [current_job, mission_reward]

func _buy_or_visit_house():
    if player.global_position.distance_to(Vector3(0,0,31)) > 18:
        message_label.text = "برای خرید خانه به ساختمان خانه فروشی نزدیک شو."
        return
    if house_owned:
        message_label.text = "به خانه خودت خوش آمدی."
    elif cash >= 2000:
        cash -= 2000
        house_owned = true
        message_label.text = "تبریک! خانه را به قیمت ۲۰۰۰ دلار خریدی."
    else:
        message_label.text = "برای خرید خانه ۲۰۰۰ دلار لازم داری."
    _refresh_hud()

func _save_game():
    var data = {"cash":cash,"job":current_job,"job_index":job_index,"house_owned":house_owned,"player":[player.position.x,player.position.y,player.position.z]}
    var f = FileAccess.open(save_path, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(data))
        message_label.text = "بازی ذخیره شد."
    else:
        message_label.text = "ذخیره بازی ناموفق بود."

func _load_game():
    if not FileAccess.file_exists(save_path): return
    var f = FileAccess.open(save_path, FileAccess.READ)
    if not f: return
    var parsed = JSON.parse_string(f.get_as_text())
    if typeof(parsed) == TYPE_DICTIONARY:
        cash = int(parsed.get("cash",cash))
        current_job = str(parsed.get("job",current_job))
        job_index = int(parsed.get("job_index", max(0, JOBS.find(current_job))))
        house_owned = bool(parsed.get("house_owned",false))
        var p = parsed.get("player",[])
        if p.size() == 3:
            player.position = Vector3(float(p[0]),float(p[1]),float(p[2]))

func _physics_process(_delta):
    if player:
        player.set("vehicle_mode", in_car)

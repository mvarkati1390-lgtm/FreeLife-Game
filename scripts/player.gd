extends CharacterBody3D

@export var speed := 7.0

func move_mobile(direction: String):
    var movement := Vector3.ZERO
    match direction:
        "up": movement.z = -1
        "down": movement.z = 1
        "left": movement.x = -1
        "right": movement.x = 1
    velocity.x = movement.x * speed
    velocity.z = movement.z * speed
    move_and_slide()

func _physics_process(_delta):
    var input_dir := Vector2(
        Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
        Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
    )
    if input_dir.length() > 0:
        input_dir = input_dir.normalized()
        velocity.x = input_dir.x * speed
        velocity.z = input_dir.y * speed
        move_and_slide()

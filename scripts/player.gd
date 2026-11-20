extends CharacterBody3D

@export var speed := 7.0
@export var gravity := 22.0
var held := {"up":false,"down":false,"left":false,"right":false}
var vehicle_mode := false

func set_mobile_direction(direction: String, pressed: bool):
    if held.has(direction):
        held[direction] = pressed

func _physics_process(delta):
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0
    var x := (1.0 if held["right"] else 0.0) - (1.0 if held["left"] else 0.0)
    var z := (1.0 if held["down"] else 0.0) - (1.0 if held["up"] else 0.0)
    var movement := Vector3(x,0,z).normalized()
    if movement.length() > 0.01:
        velocity.x = movement.x * speed
        velocity.z = movement.z * speed
        rotation.y = lerp_angle(rotation.y, atan2(movement.x,movement.z), 0.2)
    else:
        velocity.x = move_toward(velocity.x,0, speed * 0.18)
        velocity.z = move_toward(velocity.z,0, speed * 0.18)
    move_and_slide()

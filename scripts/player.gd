extends CharacterBody3D

@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
@export var can_sprint : bool = false
@export var can_freefly : bool = false

@export_group("Speeds")
@export var look_speed : float = 0.002
@export var base_speed : float = 7.0
@export var jump_velocity : float = 4.5
@export var sprint_speed : float = 10.0
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
@export var input_left : String = "ui_left"
@export var input_right : String = "ui_right"
@export var input_forward : String = "ui_up"
@export var input_back : String = "ui_down"
@export var input_jump : String = "ui_accept"
@export var input_sprint : String = "sprint"
@export var input_freefly : String = "freefly"

@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var ray_cast_3d: RayCast3D = $Head/Camera3D/RayCast3D

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false

const DIRT_BLOCK: int = 1

func _ready() -> void:
    check_input_mappings()
    look_rotation.y = rotation.y
    look_rotation.x = head.rotation.x

func _unhandled_input(event: InputEvent) -> void:
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        capture_mouse()
    if Input.is_key_pressed(KEY_ESCAPE):
        release_mouse()

    if mouse_captured and event is InputEventMouseMotion:
        rotate_look(event.relative)

    if can_freefly and Input.is_action_just_pressed(input_freefly):
        if freeflying:
            disable_freefly()
        else:
            enable_freefly()

func _physics_process(delta: float) -> void:
    if freeflying and can_freefly:
        freefly_process(delta)
        return

    if not is_on_floor() and has_gravity:
            velocity += get_gravity() * delta

    if Input.is_action_just_pressed(input_jump) and is_on_floor() and can_jump:
            velocity.y = jump_velocity

    if Input.is_action_pressed(input_sprint) and can_sprint:
        move_speed = sprint_speed
    else:
        move_speed = base_speed

    if can_move:
        var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
        var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
        if move_dir:
            velocity.x = move_dir.x * move_speed
            velocity.z = move_dir.z * move_speed
        else:
            velocity.x = move_toward(velocity.x, 0, move_speed)
            velocity.z = move_toward(velocity.z, 0, move_speed)
    else:
        velocity.x = 0
        velocity.y = 0

    if Input.is_action_just_pressed("LMB"):
        if ray_cast_3d.is_colliding() and ray_cast_3d.get_collider().has_method("destroy_block"):
                ray_cast_3d.get_collider().destroy_block(ray_cast_3d.get_collision_point() - ray_cast_3d.get_collision_normal())

    if Input.is_action_just_pressed("RMB"):
        if ray_cast_3d.is_colliding() and ray_cast_3d.get_collider().has_method("place_block"):
                ray_cast_3d.get_collider().place_block(ray_cast_3d.get_collision_point() + ray_cast_3d.get_collision_normal(), DIRT_BLOCK)

    move_and_slide()


func rotate_look(rot_input : Vector2):
    look_rotation.x -= rot_input.y * look_speed
    look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
    look_rotation.y -= rot_input.x * look_speed
    transform.basis = Basis()
    rotate_y(look_rotation.y)
    head.transform.basis = Basis()
    head.rotate_x(look_rotation.x)


func enable_freefly():
    collider.disabled = true
    freeflying = true
    velocity = Vector3.ZERO


func disable_freefly():
    collider.disabled = false
    freeflying = false


func capture_mouse():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    mouse_captured = true


func release_mouse():
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    mouse_captured = false


func freefly_process(delta: float):
        var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
        var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
        motion *= freefly_speed * delta
        move_and_collide(motion)


func check_input_mappings():
    if can_move and not InputMap.has_action(input_left):
        push_error("Movement disabled. No InputAction found for input_left: " + input_left)
        can_move = false
    if can_move and not InputMap.has_action(input_right):
        push_error("Movement disabled. No InputAction found for input_right: " + input_right)
        can_move = false
    if can_move and not InputMap.has_action(input_forward):
        push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
        can_move = false
    if can_move and not InputMap.has_action(input_back):
        push_error("Movement disabled. No InputAction found for input_back: " + input_back)
        can_move = false
    if can_jump and not InputMap.has_action(input_jump):
        push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
        can_jump = false
    if can_sprint and not InputMap.has_action(input_sprint):
        push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
        can_sprint = false
    if can_freefly and not InputMap.has_action(input_freefly):
        push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
        can_freefly = false

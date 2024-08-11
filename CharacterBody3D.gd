extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const CROUCH_SPEED = 3.0
const SPRINT_SPEED = 7.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003

const TARGET_HEIGHT = 0.617;

# crouch lerping TODO - rn this is tied to FPS, bad :(
var crouch_target_height;
var crouch_old_height;
var crouch_timer = 0.0;
const MAX_CROUCH_TIME = 10.0;

#bob variables
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

var head_y_axis = 0.0
var camera_x_axis = 0.0

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var hand = $Hand
@onready var flashlight = $Hand/flashlight

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		head_y_axis = event.relative.x * SENSITIVITY
		camera_x_axis = event.relative.y * SENSITIVITY
		head.rotate_y(-head_y_axis)
		camera.rotate_x(-camera_x_axis)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		hand.rotate_y(-head_y_axis)
		flashlight.rotate_x(-camera_x_axis)
		flashlight.rotation.x = clamp(flashlight.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		

	$CollisionShape3D.scale.y = 1.0
	$CollisionShape3D.position.y = 0.0
	if (!is_crouch_running()):
		head.position.y = TARGET_HEIGHT;
	speed = WALK_SPEED
		
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
		
	update_crouch(Input.is_action_pressed("crouch"));
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 4.0)
		
	#head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length() , 0.5, speed * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()
	
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func is_crouch_running() -> bool:
	return crouch_timer > 0;
	
func update_crouch(is_pressed: bool):
	if is_pressed:		
		$CollisionShape3D.scale.y = 0.5
		$CollisionShape3D.position.y = -0.5
		
		if (crouch_target_height == null):
			crouch_old_height = head.position.y;
			crouch_target_height = crouch_old_height / 2.0;
	
		update_crouch_head(crouch_target_height, false);
		
		speed = CROUCH_SPEED
		
		if (crouch_timer < MAX_CROUCH_TIME):
			crouch_timer += 1;	
		return;
		
	if (crouch_timer > 0):
		crouch_timer -= 1;	
		
		if (crouch_old_height != crouch_target_height):
			crouch_old_height = crouch_target_height;
		
		update_crouch_head(TARGET_HEIGHT, true);
		
		if (crouch_timer == 0):
			crouch_old_height = null;
			crouch_target_height = null;
			
		return;
		
func update_crouch_head(target: float, invert: bool):
	var time = crouch_timer / MAX_CROUCH_TIME;
	if (invert):
		time = 1 - time;
	
	head.position.y = lerp(crouch_old_height, target, time);

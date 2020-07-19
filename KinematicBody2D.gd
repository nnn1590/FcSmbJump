extends KinematicBody2D

var FcSmb = load("res://FcSmb.gd").new()

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var FcPosX=position.x
var FcPosY=position.y

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	FcSmb.Movement(Input.is_mouse_button_pressed(BUTTON_LEFT))
	if (FcSmb.GetPlayerState() == FcSmb.MovementState.Jumping && FcSmb.PosY() >= FcPosY):
		FcSmb.ResetParam(FcPosY);

	if (FcSmb.GetPlayerState() == FcSmb.MovementState.Jumping):
		pass#JumpManSprite.sprite = Images[1];
	else:
		pass#JumpManSprite.sprite = Images[0];
	position = Vector2(FcPosX, FcSmb.PosY())

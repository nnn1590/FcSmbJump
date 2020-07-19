extends Node

var VerticalPositionOrigin: int		# ジャンプ開始時の位置
var VerticalPosition: int			# 現在位置
var VerticalSpeed: int				# 速度
var VerticalForce: int				# 現在の加速度
var VerticalForceFall: int			# 降下時の加速度
var VerticalForceDecimalPart: int	# 加速度の増加値
var CorrectionValue: int			# 累積計算での補正値？

# ジャンプ開始時の初期パラメータ
var HorizontalSpeed: int = 00		# 横方向速度
var VerticalForceDecimalPartData: PoolByteArray	= [0x20, 0x20, 0x1e, 0x28, 0x28]	# 加速度の増加値
var VerticalFallForceData: PoolByteArray		= [ 0x70, 0x70, 0x60, 0x90, 0x90 ]	# 降下時の加速度
var InitialVerticalSpeedData: PoolIntArray		= [   -4,   -4,   -4,   -5,   -5 ]	# 初速度
var InitialVerticalForceData: PoolByteArray		= [ 0x00, 0x00, 0x00, 0x00, 0x00 ]	# 初期加速度

# 落下時の最大速度
var DOWN_SPEED_LIMIT: int = 0x04	# Godotではbyteはintでいいそうだ？

# 1フレ前のジャンプボタンの押下状態
var JumpBtnPrevPress: bool = false
# 地面にいるかジャンプ中か
enum MovementState {
	OnGround,
	Jumping
}

var CurrentState = MovementState.OnGround

func ResetParam(initVerticalPos: int) -> void:
	VerticalSpeed = 0
	VerticalForce = 0
	VerticalForceFall = 0
	VerticalForceDecimalPart = 0
	CurrentState = MovementState.OnGround
	CorrectionValue = 0

	VerticalPosition = initVerticalPos

func PosY() -> int:
	return VerticalPosition

func GetPlayerState():
	return CurrentState

func Movement(jumpBtnPress: bool) -> void:
	JumpCheck(jumpBtnPress)
	MoveProcess(jumpBtnPress)

	JumpBtnPrevPress = jumpBtnPress

func JumpCheck(jumpBtnPress: bool) -> void:
	# 初めてジャンプボタンが押された？
	if (jumpBtnPress == false): return
	if (JumpBtnPrevPress == true): return

	# 地面上にいる状態？
	if (CurrentState == 0):
		# ジャンプ開始準備
		PreparingJump()

func PreparingJump() -> void:
	VerticalForceDecimalPart = 0
	VerticalPositionOrigin = VerticalPosition

	CurrentState = MovementState.Jumping

	var idx: int = 0
	if (HorizontalSpeed >= 0x1c): idx+=1
	if (HorizontalSpeed >= 0x19): idx+=1
	if (HorizontalSpeed >= 0x10): idx+=1
	if (HorizontalSpeed >= 0x09): idx+=1

	VerticalForce				= VerticalForceDecimalPartData[idx]
	VerticalForceFall			= VerticalFallForceData[idx]
	VerticalForceDecimalPart	= InitialVerticalForceData[idx]
	VerticalSpeed				= InitialVerticalSpeedData[idx]


func MoveProcess(jumpBtnPress: bool) -> void:
	# 速度が0かプラスなら画面下へ進んでいるものとして落下状態の加速度に切り替える
	if (VerticalSpeed >= 0):
		VerticalForce = VerticalForceFall
	else:
		# Aボタンが離された&上昇中？
		if (jumpBtnPress == false && JumpBtnPrevPress == true):
			if (VerticalPositionOrigin - VerticalPosition  >= 1): 
				# 落下状態の加速度値に切り替える
				VerticalForce = VerticalForceFall
	Physics()


func Physics() -> void:
	# 累積計算での補正値っぽい（Qiitaの記事参照）
	var cy: int = 0
	CorrectionValue += VerticalForceDecimalPart
	if (CorrectionValue >= 256):
		CorrectionValue -= 256
		cy = 1

	# 現在位置に速度を加算 (累積計算での補正値も加算)
	VerticalPosition += VerticalSpeed + cy

	# 加速度の固定少数点部への加算
	# 1バイトをオーバーフローしたら、速度が加算される。その時、加速度の整数部は0に戻される
	VerticalForceDecimalPart += VerticalForce
	if (VerticalForceDecimalPart >= 256):
		VerticalForceDecimalPart -= 256
		VerticalSpeed+=1

	# 速度の上限チェック
	if (VerticalSpeed >= DOWN_SPEED_LIMIT):
		# 謎の判定
		if (VerticalForceDecimalPart >= 0x80):
			VerticalSpeed = DOWN_SPEED_LIMIT
			VerticalForceDecimalPart = 0x00

class_name Enemy
extends Sprite2D
## 적 하나의 상태. 움직임·충돌은 EnemyManager가 한꺼번에 처리한다.
## (수백 마리마다 _process를 돌리지 않기 위해 여기에는 데이터만 둔다)

var hp := 10.0
var max_hp := 10.0
var speed := 30.0
var damage := 8.0
var xp := 1
## 몸 크기. 공격 판정과 접촉 판정에 더해진다.
var radius := 5.0
var is_boss := false
## 램프(촛대) 같은 공격 대상 소품: 움직이지 않고 닿아도 피해가 없으며, 맞으면 깨진다
var is_prop := false
var anim_time := 0.0
var anim_fps := 4.0
## 맞고 밀려나는 속도 (점점 줄어든다)
var knock := Vector2.ZERO
## 맞았을 때 흰 테두리가 깜빡이는 남은 시간
var flash := 0.0
## 이웃과 밀어내는 힘. 매 프레임이 아니라 몇 프레임마다 다시 계산하고 그 사이에는 이 값을 쓴다.
var sep := Vector2.ZERO

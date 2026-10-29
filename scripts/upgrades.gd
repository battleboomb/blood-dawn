class_name Upgrades
extends RefCounted
## 레벨업 강화 목록 (PRD #4-P0-4, #4-P1-2, #4-P1-9).
## weapon이 true인 항목은 처음 고르면 새 무기를 얻고, 다시 고르면 그 무기가 강해진다.
## 카드에 보이는 이름·설명은 scripts/loc.gd 의 "<id>_name", "<id>_desc", "<id>_next"(무기를 다시 고를 때)에 있다.

const LIST := [
	{ "id": "claw_damage", "max": 5 },
	{ "id": "claw_speed", "max": 5 },
	{ "id": "claw_area", "max": 5 },
	{ "id": "claw_count", "max": 4 },
	{ "id": "claw_pierce", "max": 4 },
	{ "id": "max_hp", "max": 5 },
	{ "id": "move_speed", "max": 5 },
	{ "id": "pickup", "max": 5 },
	{ "id": "bats", "weapon": true, "max": 5 },
	{ "id": "spear", "weapon": true, "max": 5 },
	{ "id": "aura", "weapon": true, "max": 5 },
]


## 아직 최대 레벨이 아닌 강화 중에서 count개를 무작위로 고른다.
static func pick(levels: Dictionary, count: int) -> Array:
	var pool := LIST.filter(func(u): return levels.get(u.id, 0) < u.max)
	pool.shuffle()
	return pool.slice(0, count)


static func display_name(upgrade: Dictionary) -> String:
	return Loc.t(upgrade.id + "_name")


## 카드에 보일 설명: 이미 가진 무기는 다음 레벨에서 바뀌는 점을 보여 준다.
static func describe(upgrade: Dictionary, level: int) -> String:
	if level > 0 and upgrade.get("weapon", false):
		return Loc.t(upgrade.id + "_next")
	return Loc.t(upgrade.id + "_desc")


static func apply(id: String, game: Node) -> void:
	var player: Node = game.player
	var claw: Node = game.claw
	match id:
		"claw_damage":
			claw.damage *= 1.3
		"claw_speed":
			claw.cooldown /= 1.15
		"claw_area":
			claw.area += 0.2
		"claw_count":
			claw.count += 1
		"claw_pierce":
			claw.pierce += 1
		"max_hp":
			# 늘어난 만큼만 채운다. 잃은 체력은 램프에서 나오는 고기로만 회복한다.
			player.max_hp += 20.0
			player.hp += 20.0
			player.hp_changed.emit(player.hp, player.max_hp)
		"move_speed":
			player.max_speed *= 1.1
		"pickup":
			player.pickup_radius *= 1.3
		"bats", "spear", "aura":
			game.level_weapon(id)

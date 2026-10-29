class_name Loc
extends RefCounted
## 게임 안 문구 (영어 기본, 한국어 선택). 레벨업 화면에서 F1로 바꾼다.
## 화면에 보이는 문구는 모두 Loc.t("키")로 가져온다. 새 문구는 TEXT에 두 언어를 함께 넣는다.

static var lang := "en"

const TEXT := {
	# 첫 화면
	"start": { "en": "START", "ko": "시작" },
	"controls_move": { "en": "WASD / Arrows: Move     ESC: Pause", "ko": "WASD / 방향키: 이동     ESC: 일시정지" },
	"controls_pick": { "en": "1-3 / Space / Mouse: Choose upgrade", "ko": "1~3 / 스페이스 / 마우스: 강화 선택" },
	"controls_goal": { "en": "Attacks are automatic. Survive till dawn, then slay the boss.", "ko": "공격은 자동. 새벽까지 버티고 보스를 쓰러뜨려라." },
	# 레벨업 화면
	"levelup_title": { "en": "Blood Boils", "ko": "피가 끓어오른다" },
	"levelup_hint": { "en": "←/→ Select  ·  Space Confirm  ·  1 / 2 / 3  ·  Mouse", "ko": "←/→ 고르기  ·  스페이스 결정  ·  1 / 2 / 3  ·  마우스" },
	"lang_toggle": { "en": "F1 KOR", "ko": "F1 ENG" },
	"new_weapon": { "en": "NEW WEAPON", "ko": "새 무기" },
	# 보스
	"boss_name": { "en": "Corpse Colossus", "ko": "시체 육괴" },
	"boss_banner_title": { "en": "The Dawn Bell Tolls", "ko": "새벽 종이 울린다" },
	"boss_banner_sub": { "en": "The Corpse Colossus awakens", "ko": "시체 육괴가 깨어났다" },
	# 결과 화면
	"result_won": { "en": "Dawn Has Come", "ko": "새벽이 왔다" },
	"result_lost": { "en": "Swallowed by Darkness", "ko": "어둠에 삼켜졌다" },
	"result_won_sub": { "en": "The Corpse Colossus crumbles as the first light splits the castle.", "ko": "시체 육괴가 무너지고, 첫 햇살이 성을 가른다." },
	"result_lost_sub": { "en": "Your blood runs dry, and the vampire returns to dust in the coffin.", "ko": "피가 바닥나고, 뱀파이어는 다시 관 속의 먼지가 되었다." },
	"stat_survived": { "en": "Survived  %s", "ko": "버틴 시간  %s" },
	"stat_boss": { "en": "Boss fight  %s", "ko": "보스전  %s" },
	"stat_level": { "en": "Level  %d", "ko": "레벨  %d" },
	"stat_kills": { "en": "Kills  %d", "ko": "처치  %d" },
	"restart_hint": { "en": "R: Restart", "ko": "R: 다시 시작" },
	# 일시정지
	"paused": { "en": "Paused", "ko": "일시정지" },
	"pause_hint": { "en": "ESC: Resume   ·   R: Restart", "ko": "ESC: 계속   ·   R: 처음부터" },
	# 강화 이름과 설명 (scripts/upgrades.gd 의 id 기준)
	"claw_damage_name": { "en": "Sharpened Claws", "ko": "날 선 발톱" },
	"claw_damage_desc": { "en": "Claw damage +30%", "ko": "발톱 피해 +30%" },
	"claw_speed_name": { "en": "Frenzy", "ko": "광기" },
	"claw_speed_desc": { "en": "Attack speed +15%", "ko": "공격 속도 +15%" },
	"claw_area_name": { "en": "Rend", "ko": "찢어발기기" },
	"claw_area_desc": { "en": "Claw size +20%", "ko": "발톱 크기 +20%" },
	"claw_count_name": { "en": "Splitting Claws", "ko": "갈라지는 발톱" },
	"claw_count_desc": { "en": "Claw slashes +1", "ko": "손톱 할퀴기 개수 +1" },
	"claw_pierce_name": { "en": "Piercing Claws", "ko": "꿰뚫는 발톱" },
	"claw_pierce_desc": { "en": "Claw pierce +1", "ko": "손톱 할퀴기 적 관통 +1" },
	"max_hp_name": { "en": "Undying Flesh", "ko": "불사의 육신" },
	"max_hp_desc": { "en": "Max HP +20", "ko": "최대 체력 +20" },
	"move_speed_name": { "en": "Shadow Step", "ko": "그림자 걸음" },
	"move_speed_desc": { "en": "Move speed +10%", "ko": "이동 속도 +10%" },
	"pickup_name": { "en": "Bloodlust", "ko": "피의 갈망" },
	"pickup_desc": { "en": "Blood pickup range +30%", "ko": "핏방울 끌어오는 범위 +30%" },
	"bats_name": { "en": "Bat Swarm", "ko": "박쥐 떼" },
	"bats_desc": { "en": "Bats circle you and bite foes", "ko": "몸 주위를 도는 박쥐가 적을 물어뜯는다" },
	"bats_next": { "en": "Bats +1, damage +2", "ko": "박쥐 +1, 피해 +2" },
	"spear_name": { "en": "Blood Lance", "ko": "피의 창" },
	"spear_desc": { "en": "Hurls a piercing lance at the toughest foe", "ko": "가장 단단한 적에게 꿰뚫는 창을 던진다" },
	"spear_next": { "en": "Damage +8, faster (+1 lance at Lv3, Lv5)", "ko": "피해 +8, 더 자주 (3·5레벨에 창 +1)" },
	"aura_name": { "en": "Blood Mist", "ko": "혈무 오라" },
	"aura_desc": { "en": "A blood mist burns and slows foes nearby", "ko": "주변의 적을 피안개로 태우고 느리게 한다" },
	"aura_next": { "en": "Range +6, damage +2", "ko": "범위 +6, 피해 +2" },
}


static func t(key: String) -> String:
	var entry: Dictionary = TEXT.get(key, {})
	return entry.get(lang, entry.get("en", key))


static func toggle() -> void:
	lang = "ko" if lang == "en" else "en"

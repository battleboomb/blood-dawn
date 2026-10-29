# 주인공 4방향 시트(24x24)를 다시 만들고 Godot로 가져온다.
# 실행: & .\tools\rebuild_hero.ps1
$godot = "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe"
& $godot --headless --path . --script res://tools/gen_hero_frames.gd
& $godot --headless --path . --import | Select-String "ERROR|alucard"
& $godot --headless --path . --quit-after 60 | Select-String "SCRIPT|Parse"
Write-Output "rebuild_hero done"

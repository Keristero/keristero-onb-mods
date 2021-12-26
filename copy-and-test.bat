set game_path="C:\Users\Keris\Desktop\Latest ONB Release\Release"

xcopy .\mods %game_path%\resources\mods /s/h/e/k/f/c/y
cd %game_path%
BattleNetwork.exe -w 127.0.0.1 -r 8765
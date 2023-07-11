set game_path="C:\Users\Keris\Documents\Repos\ONB\ONBGameClients\LatestA"

xcopy .\mods %game_path%\resources\mods /s/h/e/k/f/c/y/d
cd %game_path%
BattleNetwork.exe -w 127.0.0.1 -r 8765
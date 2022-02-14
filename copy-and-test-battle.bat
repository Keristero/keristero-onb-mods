set game_path="C:\Users\Keris\Desktop\Latest ONB Release\Release"

xcopy .\mods %game_path%\resources\mods /s/h/e/k/f/c/y/d
cd %game_path%
BattleNetwork.exe -d -w keristero.xyz -r 8765 -b --mob=com.keristero.mob.ezencounters --player=com.keristero.player.Starman --folder=list.txt
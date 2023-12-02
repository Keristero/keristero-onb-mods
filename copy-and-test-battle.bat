set game_path="C:\Users\Keris\Documents\Repos\ONB\ONBGameClients\LatestA"
REM com.D3stroy3d.player.Elecman
REM com.keristero.player.Starman
REM com.discord.Konstinople.player.AquaMan
REM com.keristero.player.Villager
REM com.keristero.player.Protoman
REM com.alrysc.player.ShanghaiFighter
REM com.D3str0y3d.player.QuickmanWMoves
set player="com.keristero.player.Villager"

xcopy .\mods %game_path%\resources\mods /s/h/e/k/f/c/y/d
cd %game_path%
BattleNetwork.exe -d -w keristero.xyz -r 8765 -b --mob=com.keristero.mob.Mettaur --player=%player% --folder=list.txt
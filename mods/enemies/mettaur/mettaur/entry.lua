local shared_package_init = include("../shared/entry.lua")

function package_init(character)
    local character_info = {
        name="Mettaur",
        hp=40,
        damage=10,
        palette=_folderpath.."battle_v1.palette.png",
        height=20,
        shockwave_cascade_frame_index = 5
    }
    if character:get_rank() == Rank.V2 then
        character_info.damage = 30
        character_info.palette=_folderpath.."battle_v2.palette.png"
        character_info.hp = 80
        character_info.shockwave_cascade_frame_index = 4
    elseif character:get_rank() == Rank.V3 then
        character_info.damage = 50
        character_info.palette=_folderpath.."battle_v3.palette.png"
        character_info.hp = 120
        character_info.shockwave_cascade_frame_index = 4
    elseif character:get_rank() == Rank.SP then
        character_info.damage = 70
        character_info.palette=_folderpath.."battle_vsp.palette.png"
        character_info.hp = 120
    elseif character:get_rank() == Rank.SP then
        character_info.damage = 50
        character_info.palette=_folderpath.."battle_vrare1.palette.png"
        character_info.hp = 120
    elseif character:get_rank() == Rank.SP then
        character_info.damage = 100
        character_info.palette=_folderpath.."battle_vrare2.palette.png"
        character_info.hp = 180
    end
    shared_package_init(character,character_info)
end

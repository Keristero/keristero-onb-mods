local shared_package_init = include("../shared/entry.lua")

function package_init(character)
    local character_info = {
        name="Mettaur",
        hp=40,
        damage=10,
        palette=_folderpath.."battle_v1.palette.png",
        height=20,
        cascade_frame = 5,
        shockwave_animation="shockwave_fast.animation",
        move_delay = 38,
        can_guard = true,
        replacement_panel = nil
    }
    if character:get_rank() == Rank.V1 then
        character_info.shockwave_animation="shockwave.animation"
        character_info.can_guard = false
    end
    if character:get_rank() == Rank.V2 then
        character_info.damage = 30
        character_info.cascade_frame = 5
        character_info.palette=_folderpath.."battle_v2.palette.png"
        character_info.hp = 80
        character_info.move_delay = 32
    elseif character:get_rank() == Rank.V3 then
        character_info.damage = 50
        character_info.palette=_folderpath.."battle_v3.palette.png"
        character_info.hp = 120
        character_info.cascade_frame = 4
        character_info.move_delay = 26
    elseif character:get_rank() == Rank.SP then
        --I'm making up the frame values for SP and higher because I cant easily record them
        character_info.damage = 70
        character_info.palette=_folderpath.."battle_vsp.palette.png"
        character_info.hp = 160
        character_info.cascade_frame = 3
        character_info.move_delay = 24
    elseif character:get_rank() == Rank.Rare1 then
        character_info.damage = 50
        character_info.palette=_folderpath.."battle_vrare1.palette.png"
        character_info.hp = 120
        character_info.cascade_frame = 5
        character_info.move_delay = 26
        character_info.replacement_panel = TileState.Cracked
    elseif character:get_rank() == Rank.Rare2 then
        character_info.damage = 100
        character_info.palette=_folderpath.."battle_vrare2.palette.png"
        character_info.hp = 180
        character_info.cascade_frame = 3
        character_info.move_delay = 24
        character_info.replacement_panel = TileState.Poison
    end
    shared_package_init(character,character_info)
end

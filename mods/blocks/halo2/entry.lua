function package_init(block)
    block:declare_package_id("com.keristero.block.Halo2")
    block:set_name("Halo2")
    block:set_description("ooOOoo")
    block:set_color(Blocks.White)
    block:set_shape({
        0, 0, 0, 0, 0,
        0, 1, 0, 1, 0,
        0, 1, 1, 1, 0,
        0, 1, 0, 1, 0,
        0, 0, 0, 0, 0
    })
    block:set_mutator(modify)
end

function modify(player)
    local f = player:get_field()
    local t = player:get_tile()
    
    local q = f:tile_at(t:x(), t:y())
    q:set_state(TileState.Holy)
    halo_sound = Engine.load_audio(_modpath.."halo.ogg")
    Engine.play_audio(halo_sound, AudioPriority.Highest)
end
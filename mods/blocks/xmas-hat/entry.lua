local add_component = include('hat/hat.lua')

function package_init(block)
    block:declare_package_id("com.keristero.block.XmasHat")
    block:set_name("XmasHat")
    block:set_description("Wear hat on your hat point")
    block:set_color(Blocks.White)
    block:as_program()
    block:set_shape({
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0
    })
    block:set_mutator(modify)
end

function modify(player)
    add_component(player)
end

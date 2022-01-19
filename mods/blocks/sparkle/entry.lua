local add_sparkle_component = include('sparkle_component/sparkle_component.lua')

function package_init(block)
    block:declare_package_id("com.keristero.block.Sparkle")
    block:set_name("Sparkle")
    block:set_description("kira kira")
    block:set_color(Blocks.Yellow)
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
    add_sparkle_component(player)
end

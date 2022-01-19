local add_component = include('cloud_component/cloud_component.lua')

function package_init(block)
    block:declare_package_id("com.keristero.block.ThndrShoe")
    block:set_name("ThndrShoe")
    block:set_description("Ride cloud to battle")
    block:set_color(Blocks.Yellow)
    block:as_program()
    block:set_shape({
        0, 0, 0, 0, 0,
        0, 1, 0, 1, 0,
        0, 1, 1, 1, 0,
        1, 1, 1, 1, 1,
        0, 0, 0, 0, 0
    })
    block:set_mutator(modify)
end

function modify(player)
    add_component(player)
end

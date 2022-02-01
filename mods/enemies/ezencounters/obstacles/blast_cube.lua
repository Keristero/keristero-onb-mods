local create_obstacle_from_data = include("create_obstacle.lua")

function create_obstacle()
    local obstacle_data = {
        health = 200,
        texture = Engine.load_texture(_folderpath.."blast_cube.png"),
        animation_path = _folderpath.."blast_cube.animation",
        pushable = false,
        invincible = true,
        can_continue_sliding = false
    }
    local obstacle = create_obstacle_from_data(obstacle_data)
    return obstacle
end

return create_obstacle
local create_obstacle_from_data = include("create_obstacle.lua")

function create_obstacle()
    local obstacle_data = {
        health = 300,
        texture = Engine.load_texture(_folderpath.."coffin.png"),
        animation_path = _folderpath.."coffin.animation",
        pushable = true,
        can_continue_sliding = true
    }
    local obstacle = create_obstacle_from_data(obstacle_data)
    return obstacle
end

return create_obstacle
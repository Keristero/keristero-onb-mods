function ramdomize_test_scenario(encounter_info,flip_field)
    --while developing mods it is useful to be able to test with a wide variety of battle scenarios
    --this function will return a randomized scenario to help testing edge cases
    local random_key_from_dict = function (dict)
        local array = {}
        for key, value in pairs(dict) do
            table.insert(array,key)
        end
        return array[math.random(1,#array)]
    end
    local flip_array_x = function (array)
        local flipped_array = {}
        for y, x_table in ipairs(array) do
            table.insert(flipped_array,{})
            for x, x_val in ipairs(x_table) do
                local rev_x = #array[y]-(x-1)
                local rev_x_val = x_table[rev_x]
                table.insert(flipped_array[y],rev_x_val)
            end
        end
        return flipped_array
    end
    local procedural_populate_array = function (x_positions,y_positions,values_to_place,default_tile)
        if not default_tile then default_tile = 0 end
        local d = default_tile
        local array = {
            {d,d,d,d,d,d},
            {d,d,d,d,d,d},
            {d,d,d,d,d,d}
        }
        for i, value in ipairs(values_to_place) do
            local x = table.remove(x_positions,math.random(1,#x_positions))
            local y = table.remove(y_positions,math.random(1,#y_positions))
            array[y][x] = value
        end
        return array
    end
    local data = {
        enemies = {
            {name=random_key_from_dict(encounter_info.enemy_packages),rank=1},
            {name=random_key_from_dict(encounter_info.enemy_packages),rank=1},
            {name=random_key_from_dict(encounter_info.enemy_packages),rank=1},
        },
        player_positions = {
            {0,0,0,0,0,0},
            {0,1,0,0,0,0},
            {0,0,0,0,0,0}
        },
        obstacles = {
            {name=random_key_from_dict(encounter_info.obstacles)},
        },
    }
    --place enemy 1 2 and 3 at random positions
    local y_positions = {1,2,3}
    local x_positions = {5,6,5,6,5,6}
    local values_to_place = {1,2,3}
    data.positions = procedural_populate_array(x_positions,y_positions,values_to_place)
    --place obstacle at a random position
    local y_positions = {1,2,3}
    local x_positions = {3,4}
    local obstacle_index = math.random(0,1) --50/50 chance to have no obstacle
    data.obstacle_positions = procedural_populate_array(x_positions,y_positions,{obstacle_index})
    --randomize some tiles in top and bottom row
    local y_positions = {1,3,1,3,1,3}
    local x_positions = {1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6}
    local random_tiles = {}
    for i = 1, math.random(1,5), 1 do
        table.insert(random_tiles,math.random(1,14))
    end
    data.tiles = procedural_populate_array(x_positions,y_positions,random_tiles,1)
    --print("EZENCOUNTERS DEBUG MODE: FLIP FIELD = ",flip_field)
    if flip_field then
        data.player_positions = flip_array_x(data.player_positions)
        data.positions = flip_array_x(data.positions)
        data.obstacle_positions = flip_array_x(data.obstacle_positions)
    end
    return data
end

return ramdomize_test_scenario
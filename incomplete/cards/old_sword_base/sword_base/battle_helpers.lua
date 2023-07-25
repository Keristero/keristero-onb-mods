--Functions for easy reuse in scripts
--Version 2.2 (added highlight_tiles_update_func)
--Version 2.1 (added get_tile_relative_positions_from_pattern,get_tiles_at_relative_positions,attack_tiles,sum_relative_positions_between_animation_points)
--Version 2.0 (added reversable sort, add any_row,exclude_obstacles,exclude_characters to get first target ahead)
--Version 1.9 (added only_same_y and ignore_obstales arguments for `find targets ahead`)
--Version 1.8 (optionally ignore neutral team for get_first_target_ahead, add is_tile_free_for_movement)
--Version 1.7 (fixed find targets ahead getting non character/obstacles)

battle_helpers = {}

function battle_helpers.spawn_visual_artifact(character,tile,texture,animation_path,animation_state,position_x,position_y,dont_flip_offset)
    local visual_artifact = Battle.Artifact.new()
    --visual_artifact:hide()
    visual_artifact:set_texture(texture,true)
    local anim = visual_artifact:get_animation()
    local sprite = visual_artifact:sprite()
    local field = character:get_field()
    local facing = character:get_facing()
    anim:load(animation_path)
    anim:set_state(animation_state)
    anim:on_complete(function()
        visual_artifact:delete()
    end)
    if facing == Direction.Left and not dont_flip_offset then
        position_x = position_x *-1
    end
    visual_artifact:set_facing(facing)
    visual_artifact:set_offset(position_x,position_y)
    anim:refresh(sprite)
    field:spawn(visual_artifact, tile:x(), tile:y())
    return visual_artifact
end

function battle_helpers.find_all_enemies(user)
    local field = user:get_field()
    local user_team = user:get_team()
    local list = field:find_characters(function(character)
        if character:get_team() ~= user_team then
            --if you are not with me, you are against me
            return true
        end
    end)
    return list
end

function battle_helpers.reversable_sort(p_table,sort_function,reverse_sorting)
    --print('sorting mob tracker turn order')
    local reversable_sort = function(a,b)
        local bool_result = sort_function(a,b)
        if reverse_sorting then
            bool_result = not bool_result
        end
        return bool_result
    end
    table.sort(p_table,reversable_sort)
end

function battle_helpers.find_targets_ahead(user,any_row,exclude_obstacles,exclude_characters)
    local field = user:get_field()
    local user_tile = user:get_current_tile()
    local user_team = user:get_team()
    local user_facing = user:get_facing()
    local list = field:find_entities(function(entity)
        local not_character = Battle.Character.from(entity) == nil
        local not_obstacle = Battle.Obstacle.from(entity) == nil
        if not_character and not_obstacle then
            return false
        end
        if (not_character and exclude_obstacles) or (not_obstacle and exclude_characters) then
            return false
        end
        local entity_tile = entity:get_current_tile()
        if entity_tile:y() ~= user_tile:y() and not any_row then
            return false
        end
        if entity:get_team() == user_team then
            return false
        end
        if user_facing == Direction.Left then
            if entity_tile:x() < user_tile:x() then
                return true
            end
        elseif user_facing == Direction.Right then
            if entity_tile:x() > user_tile:x() then
                return true
            end
        end
        return false
    end)
    return list
end

function battle_helpers.get_first_target_ahead(user,ignore_neutral_team,any_row,exclude_obstacles,exclude_characters)
    local facing = user:get_facing()
    local targets = battle_helpers.find_targets_ahead(user,any_row,exclude_obstacles,exclude_characters)
    local filtered_targets = {}
    local reverse_sort = facing == Direction.Left
    if ignore_neutral_team then
        for index, target in ipairs(targets) do
            if target:get_team() ~= Team.Other then
                filtered_targets[#filtered_targets+1] = target
            end
        end
    else
        filtered_targets = targets
    end
    battle_helpers.reversable_sort(filtered_targets,function (a, b)
        return a:get_current_tile():x() < b:get_current_tile():x()
    end,reverse_sort)

    if #filtered_targets == 0 then
        return nil
    end
    return filtered_targets[1]
end

function battle_helpers.drop_trace_fx(target_artifact,lifetime_ms)
    --drop an afterimage artifact mimicking the appearance of an existing spell/artifact/character and fade it out over it's lifetime_ms
    local fx = Battle.Artifact.new()
    local anim = target_artifact:get_animation()
    local field = target_artifact:get_field()
    local offset = target_artifact:get_offset()
    local texture = target_artifact:get_texture()
    local elevation = target_artifact:get_elevation()
    fx:set_facing(target_artifact:get_facing())
    fx:set_texture(texture, true)
    fx:get_animation():copy_from(anim)
    fx:get_animation():set_state(anim:get_state())
    fx:set_offset(offset.x,offset.y)
    fx:set_elevation(elevation)
    fx:get_animation():refresh(fx:sprite())
    fx.starting_lifetime_ms = lifetime_ms
    fx.lifetime_ms = lifetime_ms
    fx.update_func = function(self, dt)
        self.lifetime_ms = math.max(0, self.lifetime_ms-math.floor(dt*1000))
        local alpha = math.floor((fx.lifetime_ms/fx.starting_lifetime_ms)*255)
        self:set_color(Color.new(0, 0, 0,alpha))

        if self.lifetime_ms == 0 then 
            self:erase()
        end
    end

	local tile = target_artifact:get_current_tile()
    field:spawn(fx, tile:x(), tile:y())
    return fx
end

function battle_helpers.get_relative_position_between_animation_points(animation,point_a_name,point_b_name)
    --gives you the difference between two points
    local point_a = animation:point(point_a_name)
    local point_b = animation:point(point_b_name)
    return {x=point_b.x-point_a.x,y=point_b.y-point_a.y}
end

function battle_helpers.sum_relative_positions_between_animation_points(animations_with_pairs_of_pointnames)
    --gives you the difference between many points
    local final_relative_position = {x=0,y=0}
    for i,animation_with_pairs_of_pointnames in ipairs(animations_with_pairs_of_pointnames) do
        local animation = animation_with_pairs_of_pointnames[1]
        local point_a_name = animation_with_pairs_of_pointnames[2]
        local point_b_name = animation_with_pairs_of_pointnames[3]
        local relative_position = battle_helpers.get_relative_position_between_animation_points(animation,point_a_name,point_b_name)
        final_relative_position.x = final_relative_position.x + relative_position.x
        final_relative_position.y = final_relative_position.y + relative_position.y
    end
    return final_relative_position
end

function battle_helpers.get_tile_relative_positions_from_pattern(pattern,include_centre)
    --0, empty space, not affected
    --1, the center tile
    --2, other tiles to attack
    local centre_tile
    local relative_positions = {}
    --find the spell tile in pattern
    for y, x_arr in ipairs(pattern) do
        for x, value in ipairs(x_arr) do
            if value == 1 then
                centre_tile = {x,y}
            end
            if value == 2 or (value == 1 and include_centre) then
                table.insert(relative_positions,{x,y})
            end
        end
    end
    --make relative
    for index, tile in ipairs(relative_positions) do
        tile[1] = tile[1]-centre_tile[1]
        tile[2] = tile[2]-centre_tile[2]
    end
    return relative_positions
end

function battle_helpers.get_tiles_at_relative_positions(field,centre_tile,relative_positions,tile_eligibility_check)
    local x = centre_tile:x()
    local y = centre_tile:y()
    local tiles = {}
    for i, position in ipairs(relative_positions) do
        local target_tile = field:tile_at(x+position[1],y+position[2])
        table.insert(tiles,target_tile)
    end 
    return tiles
end

function battle_helpers.attack_tiles(spell,tiles)
    for index, tile in ipairs(tiles) do
        tile:attack_entities(spell)
    end
end

--Call this to get a function that you can call every frame to keep the specified tiles highlighted for the specified number of frames
--Once the function is finished it will delete itself, so be sure to check for nil when calling it in your update func
--You can chose a highlight style for various highlighting animations
battle_helpers.highlight_style = {
    solid = 1,--always yellow
    fast_wave = 2,--fast wave based on tile x and y
}
function battle_helpers.highlight_tiles_update_func(tiles,max_frames,highlight_style)
    if not highlight_style then
        highlight_style = battle_helpers.highlight_style.solid
    end
    local elapsed_frames = 0
    local update_callback = nil
    --if
    if highlight_style == battle_helpers.highlight_style.solid then
        update_callback = function ()
            if elapsed_frames > max_frames then
                update_callback = nil
                return
            end
            for index, tile in ipairs(tiles) do
                tile:highlight(Highlight.Solid)
            end
            elapsed_frames = elapsed_frames + 1
        end
    end
    if highlight_style == battle_helpers.highlight_style.fast_wave then
        update_callback = function ()
            if elapsed_frames > max_frames then
                update_callback = nil
                return
            end
            for index, tile in ipairs(tiles) do
                local i = elapsed_frames+tile:x()+tile:y()
                if i % 8 > 2 then
                    tile:highlight(Highlight.None)
                else
                    tile:highlight(Highlight.Solid)
                end
            end
            elapsed_frames = elapsed_frames + 1
        end
    end
    return update_callback
end

function battle_helpers.is_tile_free_for_movement(tile,character,must_be_walkable)
    --Basic check to see if a tile is suitable for a chracter of a team to move to
    if tile:get_team() ~= character:get_team() and tile:get_team() ~= Team.Other then 
        return false 
    end
    if not tile:is_walkable() and must_be_walkable then 
        return false 
    end
    if tile:is_edge() or tile:is_hidden() then
        return false
    end
    local occupants = tile:find_entities(function(other_entity)
        if Battle.Character.from(other_entity) == nil and Battle.Obstacle.from(other_entity) == nil then
            --if it is not a character and it is not an obstacle
            return false
        end
        return true
    end)
    if #occupants > 0 then 
        return false
    end
    
    return true
end

return battle_helpers
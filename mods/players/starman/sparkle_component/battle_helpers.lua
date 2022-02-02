--Functions for easy reuse in scripts
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

function battle_helpers.find_targets_ahead(user)
    local field = user:get_field()
    local user_tile = user:get_current_tile()
    local user_team = user:get_team()
    local user_facing = user:get_facing()
    local list = field:find_entities(function(entity)
        if Battle.Character.from(entity) == nil and Battle.Obstacle.from(entity) == nil then
            return false
        end
        local entity_tile = entity:get_current_tile()
        if entity_tile:y() == user_tile:y() and entity:get_team() ~= user_team then
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
        end
    end)
    return list
end

function battle_helpers.get_first_target_ahead(user,ignore_neutral_team)
    local facing = user:get_facing()
    local targets = battle_helpers.find_targets_ahead(user)
    local filtered_targets = {}
    if ignore_neutral_team then
        for index, target in ipairs(targets) do
            if target:get_team() ~= Team.Other then
                filtered_targets[#filtered_targets+1] = target
            end
        end
    else
        filtered_targets = targets
    end
    table.sort(filtered_targets,function (a, b)
        return a:get_current_tile():x() > b:get_current_tile():x()
    end)
    if #filtered_targets == 0 then
        return nil
    end
    if filtered_targets == Direction.Left then
        return filtered_targets[1]
    else
        return filtered_targets[#filtered_targets]
    end
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
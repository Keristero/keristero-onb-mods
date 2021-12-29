--Functions for easy reuse in scripts
--Version 1.1

battle_helpers = {}

function battle_helpers.spawn_visual_artifact(character,tile,texture,animation_path,animation_state,position_x,position_y)
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
    if facing == Direction.Left then
        position_x = position_x *-1
    end
    visual_artifact:set_offset(position_x,position_y)
    anim:refresh(sprite)
    field:spawn(visual_artifact, tile:x(), tile:y())
end

function battle_helpers.find_targets_ahead(user)
    local field = user:get_field()
    local user_tile = user:get_current_tile()
    local user_team = user:get_team()
    local list = field:find_characters(function(character)
        return character:get_current_tile():y() == user_tile:y() and character:get_team() ~= user_team
    end)
    return list
end

function battle_helpers.get_first_target_ahead(user)
    local facing = user:get_facing()
    local targets = battle_helpers.find_targets_ahead(user)
    table.sort(targets,function (a, b)
        return a:get_current_tile():x()-b:get_current_tile():x()
    end)
    if #targets == 0 then
        return nil
    end
    if facing == Direction.Left then
        return targets[1]
    else
        return targets[#targets]
    end
end

return battle_helpers
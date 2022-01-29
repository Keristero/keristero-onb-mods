--Functions for easy reuse in scripts
--Version 1.2

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
    local list = field:find_characters(function(character)
        if character:get_current_tile():y() == user_tile:y() and character:get_team() ~= user_team then
            if user_facing == Direction.Left then
                if character:get_current_tile():x() < user_tile:x() then
                    return true
                end
            elseif user_facing == Direction.Right then
                if character:get_current_tile():x() > user_tile:x() then
                    return true
                end
            end
            return false
        end
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

function battle_helpers.drop_trace_fx(target_artifact,lifetime_ms)
    --drop an afterimage artifact mimicking the appearance of an existing spell/artifact/character and fade it out over it's lifetime_ms
    local fx = Battle.Artifact.new()
    local anim = target_artifact:get_animation()
    local field = target_artifact:get_field()
    local offset = target_artifact:get_offset()
    local texture = target_artifact:get_texture()
    fx:set_facing(target_artifact:get_facing())
    fx:set_texture(texture, true)
    fx:get_animation():copy_from(anim)
    fx:get_animation():set_state(anim:get_state())
    fx:set_offset(offset.x,offset.y)
    fx:get_animation():refresh(fx:sprite())
    fx.starting_lifetime_ms = lifetime_ms
    fx.lifetime_ms = lifetime_ms
    fx.update_func = function(self, dt)
        self.lifetime_ms = math.max(0, self.lifetime_ms-math.floor(dt*1000))
        self:set_color(Color.new(0, 0, 0, math.floor(fx.lifetime_ms/fx.starting_lifetime_ms)*255))

        if self.lifetime_ms == 0 then 
            self:erase()
        end
    end

	local tile = target_artifact:get_current_tile()
    field:spawn(fx, tile:x(), tile:y())
end

return battle_helpers
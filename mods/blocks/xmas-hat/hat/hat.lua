local battle_helpers = include("battle_helpers.lua")

local texture = Engine.load_texture(_folderpath .. "hat.png")
local animation = _folderpath.. "hat.animation"

local function spawn_hat(character)
    local visual_artifact = Battle.Artifact.new()
    --visual_artifact:hide()
    visual_artifact:set_texture(texture,true)
    local anim = visual_artifact:get_animation()
    local sprite = visual_artifact:sprite()
    local field = character:get_field()
    local facing = character:get_facing()
    local tile = character:get_current_tile()
    anim:load(animation)
    anim:set_state("IDLE")
    anim:set_playback(Playback.Loop)
    sprite:set_layer(-1)
    visual_artifact:set_facing(facing)
    visual_artifact:set_air_shoe(true)
    visual_artifact:set_float_shoe(true)
    anim:refresh(sprite)
    field:spawn(visual_artifact, tile:x(), tile:y())
    visual_artifact.can_move_to_func = function ()
        return true 
    end
    visual_artifact:show_shadow(false)
    local player_animation = character:get_animation()
    local points = {{player_animation,"ORIGIN","HAT"}}
    local end_point_relative = battle_helpers.sum_relative_positions_between_animation_points(points)
    if end_point_relative.x ~= 0 and end_point_relative.y ~= 0 then
        visual_artifact:reveal()
        visual_artifact:set_offset(end_point_relative.x*2,end_point_relative.y*2)
    end

    return visual_artifact
end

local function add_component(character)
    local c = Battle.Component.new(character, Lifetimes.Battlestep)
    c.update_func = function(self, dt)
        local player = self:get_owner()
        local player_animation = player:get_animation()
        local player_elevation = player:get_elevation()
        local player_offset = player:get_offset()

        if self:get_owner():get_health() == 0 then
            c:cleanup_func()
            self:eject()
            return
        end

        if c.hat_artifact then
            --update hat position
            c.hat_artifact:set_elevation(player_elevation)

            local points = {{player_animation,"ORIGIN","HAT"}}
            local end_point_relative = battle_helpers.sum_relative_positions_between_animation_points(points)
            if end_point_relative.x ~= 0 and end_point_relative.y ~= 0 then
                c.hat_artifact:reveal()
                local x = player_offset.x+end_point_relative.x*2
                local y = player_offset.y+end_point_relative.y*2
                c.hat_artifact:set_offset(x,y)
            end

            local player_tile = player:get_current_tile()
            local cloud_tile = c.hat_artifact:get_current_tile()
            if cloud_tile:x() ~= player_tile:x() or cloud_tile:y() ~= player_tile:y() then
                c.hat_artifact:teleport(player_tile,ActionOrder.Immediate)
            end
        end
    end

    c.cleanup_func = function (self)
        if c.hat_artifact then
            c.hat_artifact:delete()
        end
    end

    c.scene_inject_func = function(self)
        local player = self:get_owner()
        c.hat_artifact = spawn_hat(player)
        c.hat_artifact:hide()
    end
    -- add to character
    character:register_component(c)
    return c
end

return add_component
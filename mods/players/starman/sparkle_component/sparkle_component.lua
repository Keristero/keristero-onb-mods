local sub_folder_path = _modpath.."/sparkle_component/" --folder we are inside

local starman_effects_texture = Engine.load_texture(sub_folder_path .. "effects.png")
local starman_effects_texture_animation_path = sub_folder_path.. "effects.animation"
local battle_helpers = include("battle_helpers.lua")

local function add_component(character)
    local c = Battle.Component.new(character, Lifetimes.Battlestep)
    c.movement_sparkles = 3
    c.update_func = function(self, dt)
        local player = self:get_owner()
        if self:get_owner():get_health() == 0 then
            self:eject()
            return
        end

        if player:is_moving() then
            local current_tile = player:get_current_tile()
            if c.movement_sparkles > 0 and not player.dont_sparkle then
                local artifact = battle_helpers.spawn_visual_artifact(player,current_tile,starman_effects_texture,starman_effects_texture_animation_path,"SPARKLE",math.random(-40,40),math.random(-90,-30))
                if math.random(1,2) == 2 then
                    artifact:set_facing(Direction.reverse(artifact:get_facing()))
                end
                c.movement_sparkles = c.movement_sparkles - 1
            end
        end
        if not player:is_moving() then
            c.movement_sparkles = 3
        end
    end

    c.scene_inject_func = function(self)
    end

    -- add to character
    character:register_component(c)
    return c
end

return add_component
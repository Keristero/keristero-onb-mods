local guard_hit_effect_texture = Engine.load_texture(_folderpath .. "guard_hit.png")
local guard_hit_effect_animation_path = _folderpath .. "guard_hit.animation"
local tink_sfx = Engine.load_audio(_folderpath .. "tink.ogg")
local battle_helpers = include("battle_helpers.lua")

local function create_obstacle_from_data(obstacle_data)
    local obstacle = Battle.Obstacle.new(Team.Other)
    obstacle:set_health(obstacle_data.health)
    obstacle:set_texture(obstacle_data.texture, true)
    local anim = obstacle:get_animation()
    local continued_slide_dir = Direction.None
    anim:load(obstacle_data.animation_path)
    anim:set_state("IDLE")
    anim:set_playback(Playback.Loop)

    local props = HitProps.new(obstacle_data.health,
                               Hit.Impact | Hit.Flinch | Hit.Flash,
                               Element.None, nil, Drag.None)
    obstacle:set_hit_props(props)

    local destroy_obstacle_func = function (obstacle)
        if not obstacle_data.is_mystery then
            anim:set_state("DESTROY")
            anim:on_complete(function() obstacle:delete() end)
        else
            obstacle:delete()
        end
    end

    if obstacle_data.invincible then
        local invincible_defense_rule = Battle.DefenseRule.new(0,DefenseOrder.Always)
        invincible_defense_rule.can_block_func = function(judge, attacker, defender)
            local attacker_hit_props = attacker:copy_hit_props()
            if attacker_hit_props.damage > 0 then
                judge:block_impact()
                judge:block_damage()
                Engine.play_audio(tink_sfx, AudioPriority.Highest)
                battle_helpers.spawn_visual_artifact(obstacle,obstacle:get_current_tile(),guard_hit_effect_texture,guard_hit_effect_animation_path,"DEFAULT",0,-30)
            end
        end
        obstacle:add_defense_rule(invincible_defense_rule)
    end

    if obstacle_data.insta_break then
        local insta_break = Battle.DefenseRule.new(-1,DefenseOrder.Always)
        insta_break.can_block_func = function(judge, attacker, defender)
            local attacker_hit_props = attacker:copy_hit_props()
            if attacker_hit_props.damage > 0 then
                if attacker_hit_props.flags & Hit.Breaking == Hit.Breaking then
                    destroy_obstacle_func(obstacle)
                end
            end
        end
        obstacle:add_defense_rule(insta_break)
    end

    obstacle.can_move_to_func = function(tile)
        local current_tile = obstacle:get_current_tile()
        if not obstacle_data.pushable then return false end
        if not tile:is_walkable() or tile:is_edge() then return false end
        if obstacle_data.can_continue_sliding then
            if tile:x() > current_tile:x() then
                continued_slide_dir = Direction.Right
            else
                if tile:x() < current_tile:x() then
                    continued_slide_dir = Direction.Left
                end
            end
            return true
        end
    end
    obstacle.attack_func = function(self)
        destroy_obstacle_func(self)
    end
    obstacle.update_func = function(self, dt)
        local tile = self:get_current_tile()
        if not tile:is_walkable() or tile:is_edge() or self:get_health() <= 0 then
            self:delete()
            return
        end
        tile:attack_entities(obstacle)
        if not self:is_sliding() and continued_slide_dir ~= Direction.None then
            self:slide(self:get_tile(continued_slide_dir, 1), frames(6),frames(0), ActionOrder.Voluntary)
        end
    end
    return obstacle
end

return create_obstacle_from_data

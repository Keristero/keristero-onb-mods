local battle_helpers = include("battle_helpers.lua")

local sub_folder_path = _modpath.."/guard/" --folder we are inside

local wave_texture = Engine.load_texture(sub_folder_path .. "shockwave.png")
local wave_sfx = Engine.load_audio(sub_folder_path .. "shockwave.ogg")
local shield_texture = Engine.load_texture(sub_folder_path .. "guard_attachment.png")
local sheild_animation_path = sub_folder_path .. "guard_attachment.animation"
local guard_hit_effect_texture = Engine.load_texture(sub_folder_path .. "guard_hit.png")
local guard_hit_effect_animation_path = sub_folder_path .. "guard_hit.animation"
local tink_sfx = Engine.load_audio(sub_folder_path .. "tink.ogg")
local shield_sfx = Engine.load_audio(sub_folder_path .. "shield.ogg")

--variables that change for each version of the card
local guard = {
    name="Guard1",
    codes={'A',"D","K","*"},
    damage=50,
    duration=1.024,
    guard_animation = "GUARD1",
    description = "Repels an enemys attack"
}

function guard.card_create_action(user,props)
    local action = Battle.CardAction.new(user, "PLAYER_SHOOTING")
    --special properties
    action.guard_animation = guard.guard_animation

	--protoman's counter in BN5 lasts 24 frames (384ms)
	--there are 224ms of the shield fading away where protoman can move
	action:set_lockout(make_animation_lockout())
	local GUARDING = {1,guard.duration}
	local POST_GUARD = {1, 0.224} 
	local FRAMES = make_frame_data({GUARDING,POST_GUARD})
    action.action_end_func = function ()
        user:remove_defense_rule(action.guarding_defense_rule)
    end
	action:override_animation_frames(FRAMES)

    action.execute_func = function(self, user)
        --local props = self:copy_metadata()
		local guarding = false
        local guard_attachment = self:add_attachment("BUSTER")
        local guard_sprite = guard_attachment:sprite()
        guard_sprite:set_texture(shield_texture)
        guard_sprite:set_layer(-2)

        local guard_animation = guard_attachment:get_animation()
        guard_animation:load(sheild_animation_path)
        guard_animation:set_state(action.guard_animation)

        action.guarding_defense_rule = Battle.DefenseRule.new(0,DefenseOrder.Always)

		self:add_anim_action(1,function()
			guarding = true
            Engine.play_audio(shield_sfx, AudioPriority.Highest)
		end)
		self:add_anim_action(2,function()
			guard_animation:set_state("FADE")
			guarding = false
            user:remove_defense_rule(action.guarding_defense_rule)
		end)

        action.guarding_defense_rule.can_block_func = function(judge, attacker, defender)
            if not guarding then 
                return 
            end
            local attacker_hit_props = attacker:copy_hit_props()
            if attacker_hit_props.damage > 0 then
                if attacker_hit_props.flags & Hit.Breaking == Hit.Breaking then
                    --cant block breaking hits with guard
                    return
                end
                judge:block_impact()
                judge:block_damage()
                Engine.play_audio(tink_sfx, AudioPriority.Highest)
                local reflected_damage = props.damage
                local direction = user:get_facing()
                if not action.guarding_defense_rule.has_reflected then
                    battle_helpers.spawn_visual_artifact(user,user:get_current_tile(),guard_hit_effect_texture,guard_hit_effect_animation_path,"DEFAULT",0,-30)
                    spawn_shockwave(user, user:get_team(),user:get_field(),user:get_tile(direction, 1), direction,reflected_damage, wave_texture,wave_sfx,0.2)
                    action.guarding_defense_rule.has_reflected = true
                end
            end
        end

        user:add_defense_rule(action.guarding_defense_rule)
    end

    return action
end

function spawn_shockwave(owner, team, field, tile, direction,damage, wave_texture, wave_sfx,frame_time)
    local spawn_next
    spawn_next = function()
        if not tile:is_walkable() then return end

        Engine.play_audio(wave_sfx, AudioPriority.Highest)

        local spell = Battle.Spell.new(team)
        spell:set_facing(direction)
        spell:highlight_tile(Highlight.Solid)
        spell:set_hit_props(HitProps.new(damage, Hit.Impact|Hit.Flash, Element.None, owner:get_context() , Drag.None))

        local sprite = spell:sprite()
        sprite:set_texture(wave_texture)

        local animation = spell:get_animation()
        animation:load(sub_folder_path .. "shockwave.animation")
        animation:set_state("DEFAULT")
        animation:refresh(sprite)
        animation:on_frame(3, function()
            tile = tile:get_tile(direction, 1)
            spawn_next()
        end, true)
        animation:on_complete(function() spell:erase() end)

        spell.update_func = function()
            spell:get_current_tile():attack_entities(spell)
        end

        field:spawn(spell, tile)
    end

    spawn_next()
end

return guard
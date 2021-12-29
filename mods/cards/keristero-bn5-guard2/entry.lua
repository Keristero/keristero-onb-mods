local battle_helpers = include("battle_helpers.lua")

local debug = true
function debug_print(text)
    if debug then
        print("[guard] " .. text)
    end
end

local wave_texture = Engine.load_texture(_modpath .. "shockwave.png")
local wave_sfx = Engine.load_audio(_modpath .. "shockwave.ogg")
local shield_texture = Engine.load_texture(_modpath .. "guard_attachment.png")
local sheild_animation_path = _modpath .. "guard_attachment.animation"
local guard_hit_effect_texture = Engine.load_texture(_modpath .. "guard_hit.png")
local guard_hit_effect_animation_path = _modpath .. "guard_hit.animation"
local tink_sfx = Engine.load_audio(_modpath .. "tink.ogg")

--variables that change for each version of the card
local guard_details = {
    name="Guard2",
    codes={'B',"L","Q","*"},
    damage=100,
    duration=1.024,
    guard_animation = "GUARD2"
}

function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = guard_details.name
    props.damage = guard_details.damage
    props.time_freeze = false
    props.element = Element.None
    props.description = "Repels an enemys attack"

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview_"..props.shortname..".png"))
    package:set_codes(guard_details.codes)
end

function card_create_action(actor,props)
    debug_print("in create_card_action()!")

    local action = Battle.CardAction.new(actor, "PLAYER_SHOOTING")
    --special properties
    action.guard_animation = guard_details.guard_animation

	--protoman's counter in BN5 lasts 24 frames (384ms)
	--there are 224ms of the shield fading away where protoman can move
	action:set_lockout(make_async_lockout(guard_details.duration))
	local GUARDING = {1,guard_details.duration}
	local POST_GUARD = {1, 0.224} 
	local FRAMES = make_frame_data({GUARDING,POST_GUARD})
	action:override_animation_frames(FRAMES)

    action.execute_func = function(self, user)
        --local props = self:copy_metadata()
		local guarding = false
        local guard_attachment = self:add_attachment("BUSTER")
        local guard_sprite = guard_attachment:sprite()
        guard_sprite:set_texture(shield_texture)
        guard_sprite:set_layer(-2)
        guard_sprite:enable_parent_shader(true)

        local guard_animation = guard_attachment:get_animation()
        guard_animation:load(sheild_animation_path)
        guard_animation:set_state(action.guard_animation)

        local guarding_defense_rule = Battle.DefenseRule.new(0,DefenseOrder.Always)

		self:add_anim_action(1,function()
			guarding = true
		end)
		self:add_anim_action(2,function()
			guard_animation:set_state("FADE")
			guarding = false
            user:remove_defense_rule(guarding_defense_rule)
		end)

        guarding_defense_rule.can_block_func = function(judge, attacker, defender)
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
                local direction = actor:get_facing()
                if not guarding_defense_rule.has_reflected then
                    battle_helpers.spawn_visual_artifact(actor,actor:get_current_tile(),guard_hit_effect_texture,guard_hit_effect_animation_path,"DEFAULT",0,-30)
                    spawn_shockwave(actor, actor:get_team(),actor:get_field(),actor:get_tile(direction, 1), direction,reflected_damage, wave_texture,wave_sfx,0.2)
                    guarding_defense_rule.has_reflected = true
                end
            end
        end

        user:add_defense_rule(guarding_defense_rule)
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
        animation:load(_modpath .. "shockwave.animation")
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

-- Based on Konst's mettaur player code
nonce = function() end

local wave_texture = Engine.load_texture(_modpath .. "shockwave.png")
local wave_sfx = Engine.load_audio(_modpath .. "shockwave.ogg")
local shield_texture = Engine.load_texture(_modpath .. "protoshield.png")
local sheild_animation_path = _modpath .. "protoshield.animation"
local tink_sfx = Engine.load_audio(_modpath .. "tink.ogg")

local DAMAGE = 50 --should be overriden by caller with action.damage

function package_init(package)
    package:declare_package_id("com.keristero.card.protoreflect")
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes({'*'})

    local props = package:get_card_props()
    props.shortname = "ProtoReflc"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.Sword
    props.description = "Protoman reflect"
end

function card_create_action(actor, props)
    print("in create_card_action()!")

    local action = Battle.CardAction.new(actor, "PLAYER_SHOOTING")
	action.damage = DAMAGE
	--protoman's counter in BN5 lasts 24 frames (384ms)
	--there are 224ms of the shield fading away where protoman can move
	local guarding_duration = 0.384
	action:set_lockout(make_async_lockout(guarding_duration))
	local GUARDING = {1,0.384}
	local POST_GUARD = {1, 0.224} 
	local FRAMES = make_frame_data({GUARDING,POST_GUARD})
	action:override_animation_frames(FRAMES)

    action.execute_func = function(self, user, props)
		local guarding = false

		self:add_anim_action(1,function()
			guarding = true
			local shield = self:add_attachment("BUSTER")
			local shield_sprite = shield:sprite()
			shield_sprite:set_texture(shield_texture)
			shield_sprite:set_layer(-2)
			shield_sprite:enable_parent_shader(true)
			local sheild_animation = shield:get_animation()
			sheild_animation:load(sheild_animation_path)
			sheild_animation:set_state("IDLE")
		end)
		self:add_anim_action(2,function()
			guarding = false
		end)

        local hiding_defense_rule = Battle.DefenseRule.new(0,DefenseOrder.Always)
        hiding_defense_rule.can_block_func = function(judge, attacker, defender)
                if not guarding then 
					return 
				end

                judge:block_impact()

                if attacker:copy_hit_props().damage > 0 then
                    judge:block_damage()
                    Engine.play_audio(tink_sfx, AudioPriority.Highest)
                    local direction = actor:get_facing()
                    spawn_shockwave(actor:get_id(), actor:get_team(),actor:get_field(),actor:get_tile(direction, 1), direction,action.damage, wave_texture,wave_sfx)
                end
            end
        actor:add_defense_rule(hiding_defense_rule)
    end

    return action
end

function spawn_shockwave(owner_id, team, field, tile, direction,damage, wave_texture, wave_sfx)
    local spawn_next

    spawn_next = function()
        if not tile:is_walkable() then return end

        Engine.play_audio(wave_sfx, AudioPriority.Highest)

        local spell = Battle.Spell.new(team)
        spell:set_facing(direction)
        spell:highlight_tile(Highlight.Solid)
        spell:set_hit_props(HitProps.new(damage, Hit.Flash, Element.None, owner_id, Drag.new()))

        local sprite = spell:sprite()
        sprite:set_texture(wave_texture)

        local animation = spell:get_animation()
        animation:load(_modpath .. "shockwave.animation")
        animation:set_state("DEFAULT")
        animation:on_frame(4, function()
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

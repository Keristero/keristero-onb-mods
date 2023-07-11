-- Based on Claris' longsword with some mods
nonce = function() end

local sub_folder_path = _modpath.."/throw-card/" --folder we are inside
local AUDIO = Engine.load_audio(sub_folder_path.."sfx.ogg")

local throw_card = {

}

throw_card.card_create_action = function(user, props)
    local action = Battle.CardAction.new(user, "PLAYER_SWORD")
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
		self:add_anim_action(3,
			function()
				local hilt = self:add_attachment("HILT")
				local hilt_sprite = hilt:sprite()
				hilt_sprite:set_texture(user:get_texture())
				hilt_sprite:set_layer(-2)
				
				local hilt_anim = hilt:get_animation()
				hilt_anim:copy_from(user:get_animation())
				hilt_anim:set_state("HAND")
			end
		)
	end
    return action
end

function create_slash(user, animation_state,damage)
	local spell = Battle.Spell.new(user:get_team())
	spell:set_facing(user:get_facing())
	spell:set_hit_props(
		HitProps.new(
			damage,
			Hit.Impact | Hit.Flinch | Hit.Flash,
			Element.Sword,
			user:get_context(),
			Drag.None
		)
	)
	spell.update_func = function(self, dt)
		self:get_tile():attack_entities(self)
	end

	spell.can_move_to_func = function(tile)
		return true
	end

	Engine.play_audio(AUDIO, AudioPriority.Low)
	return spell
end

return throw_card
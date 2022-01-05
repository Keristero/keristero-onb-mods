-- Based on Claris' longsword with some mods
nonce = function() end

local DAMAGE = 80 --default damage (should be overriden by caller with action.damage)
local sub_folder_path = _modpath.."/sword/" --folder we are inside
local SLASH_TEXTURE = Engine.load_texture(sub_folder_path.."spell_sword_slashes.png")
local BLADE_TEXTURE = Engine.load_texture(sub_folder_path.."spell_sword_blades.png")
local AUDIO = Engine.load_audio(sub_folder_path.."sfx.ogg")

local sword = {

}

sword.card_create_action = function(user, props)
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
				hilt_anim:set_state("HILT")

				local blade = hilt:add_attachment("ENDPOINT")
				local blade_sprite = blade:sprite()
				blade_sprite:set_texture(BLADE_TEXTURE)
				blade_sprite:set_layer(-1)

				local blade_anim = blade:get_animation()
				blade_anim:load(sub_folder_path.."spell_sword_blades.animation")
				blade_anim:set_state("DEFAULT")
			end
		)

		self:add_anim_action(4,
			function()
				local sword = create_slash(user, "WIDE",props.damage)
				local tile = user:get_tile(user:get_facing(), 1)
				local sharebox1 = Battle.SharedHitbox.new(sword, 0.15)
				sharebox1:set_hit_props(sword:copy_hit_props())
				local sharebox2 = Battle.SharedHitbox.new(sword, 0.15)
				sharebox2:set_hit_props(sword:copy_hit_props())
				user:get_field():spawn(sharebox1, tile:get_tile(Direction.Up, 1))
				user:get_field():spawn(sword, tile)
				user:get_field():spawn(sharebox2, tile:get_tile(Direction.Down, 1))
				local fx = Battle.Artifact.new()
				fx:set_facing(sword:get_facing())
				local anim = fx:get_animation()
				fx:set_texture(SLASH_TEXTURE, true)
				anim:load(sub_folder_path.."spell_sword_slashes.animation")
				anim:set_state("WIDE")
				anim:on_complete(
					function()
						fx:erase()
						sword:erase()
					end
				)
				user:get_field():spawn(fx, tile)
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

return sword
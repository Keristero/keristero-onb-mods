local battle_helpers = include('battle_helpers.lua')

local arrow_texture = Engine.load_texture(_folderpath .. "arrow.png")
local arrow_animation = _folderpath.. "arrow.animation"
local starfall_sfx = Engine.load_audio(_folderpath.."arrow_shot.ogg")

--variables that change for each version of the card
local arrow = {
    damage=100,
    frames_per_tile=1
}

function arrow.card_create_action(user,props)
    local action = Battle.CardAction.new(user, "BOW")
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
		self:add_anim_action(13,function()
            spell_arrow(user,props)
		end)
    end
    return action
end

function spell_arrow(character,props)
    Engine.play_audio(starfall_sfx, AudioPriority.Highest)
    local field = character:get_field()
    local facing = character:get_facing()
    local team = character:get_team()
    local tile = character:get_current_tile()
    local spell = Battle.Spell.new(team)
    local anim = spell:get_animation()
    local sprite = spell:sprite()
    sprite:set_layer(-2)
    spell:set_texture(arrow_texture,true)
    anim:load(arrow_animation)
    anim:set_state("DEFAULT")
    anim:refresh(sprite)
    anim:set_playback(Playback.Loop)
    spell:set_facing(facing)
    spell:set_offset(0,-50)
    spell:set_hit_props(HitProps.new(
        props.damage,
        Hit.Flinch,
        Element.None,
        character:get_context(),
        Drag.None)
    )
    spell.started_sliding = false
    spell.attack_func = function ()
        spell:delete()
    end
    spell.update_func = function (self)
        local current_tile = spell:get_current_tile()
        if not spell:is_sliding() then
            if current_tile:is_edge() then
                spell:delete()
                return
            end
            local next_tile = spell:get_tile(spell:get_facing(),1)
            spell.started_sliding = spell:slide(next_tile, frames(arrow.frames_per_tile), frames(0), ActionOrder.Immediate)
        end
        current_tile:attack_entities(self)
    end
    spell.can_move_to_func = function ()
        return true
    end
    field:spawn(spell, tile:x(), tile:y())
    return spell
end

return arrow
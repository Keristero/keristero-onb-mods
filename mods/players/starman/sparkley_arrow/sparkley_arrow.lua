local battle_helpers = include('battle_helpers.lua')
local sub_folder_path = _modpath.."/sparkley_arrow/" --folder we are inside

local starman_effects_texture = Engine.load_texture(sub_folder_path .. "effects.png")
local starman_effects_texture_animation_path = sub_folder_path.. "effects.animation"
--local starfall_sfx = Engine.load_audio(sub_folder_path.."starfall.ogg")

--variables that change for each version of the card
local arrow = {
    damage=30,
    frames_per_tile=4
}

function arrow.card_create_action(user,props)
    local action = Battle.CardAction.new(user, "PLAYER_ARROW")
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
		self:add_anim_action(2,function()
            local field = user:get_field()
            local target_tile = user:get_tile(user:get_facing(),3)
            spell_sparkley_arrow(user,props)
		end)
    end
    return action
end

function spell_sparkley_arrow(character,props)
    print('created arrow')
    --Engine.play_audio(starfall_sfx, AudioPriority.Highest)
    local field = character:get_field()
    local facing = character:get_facing()
    local team = character:get_team()
    local tile = character:get_current_tile()
    local spell = Battle.Spell.new(team)
    local anim = spell:get_animation()
    local sprite = spell:sprite()
    sprite:set_layer(-2)
    spell:set_texture(starman_effects_texture,true)
    anim:load(starman_effects_texture_animation_path)
    anim:set_state("ARROW")
    anim:refresh(sprite)
    anim:set_playback(Playback.Loop)
    spell:set_facing(facing)
    spell:set_offset(0,-75)
    spell:set_hit_props(HitProps.new(
        props.damage,
        Hit.Stun,
        Element.None,
        character:get_context(),
        Drag.None)
    )
    spell.started_sliding = false
    spell.attack_func = function ()
        spawn_arrow_sparkles(character,spell:get_current_tile())
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
    spawn_arrow_sparkles(character,tile)
    return spell
end

function spawn_arrow_sparkles(character,target_tile)
    for i = 1, 3, 1 do
        local x_offset = math.random(-40,40)
        local y_offset = math.random(-80,-40)
        local artifact = battle_helpers.spawn_visual_artifact(character,target_tile,starman_effects_texture,starman_effects_texture_animation_path,"SPARKLE",x_offset,y_offset)
        if math.random(1,2) == 2 then
            artifact:set_facing(Direction.reverse(artifact:get_facing()))
        end
    end
end


return arrow
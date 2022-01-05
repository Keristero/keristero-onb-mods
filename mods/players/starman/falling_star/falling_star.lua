local sub_folder_path = _modpath.."/falling_star/" --folder we are inside

local starman_effects_texture = Engine.load_texture(sub_folder_path .. "effects.png")
local starman_effects_texture_animation_path = sub_folder_path.. "effects.animation"
local starfall_sfx = Engine.load_audio(sub_folder_path.."starfall.ogg")

--variables that change for each version of the card
local falling_star = {
    damage=50
}

function falling_star.card_create_action(user,props)
    local action = Battle.CardAction.new(user, "PLAYER_SHOOTING")
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
		self:add_anim_action(1,function()
            local field = user:get_field()
            local target_tile = user:get_tile(user:get_facing(),3)
            if target_tile then
                local falling_star = spell_falling_star(user,props)
                field:spawn(falling_star, target_tile:x(), target_tile:y())
            end
		end)
        Engine.play_audio(starfall_sfx, AudioPriority.Highest)
    end
    return action
end

function spell_falling_star(character,props)
    print('created star')
    local facing = character:get_facing()
    local team = character:get_team()
    local spell = Battle.Spell.new(team)
    local anim = spell:get_animation()
    local sprite = spell:sprite()
    sprite:set_layer(-2)
    spell:set_texture(starman_effects_texture,true)
    anim:load(starman_effects_texture_animation_path)
    anim:set_state("STAR")
    anim:refresh(sprite)
    anim:set_playback(Playback.Loop)
    spell.frames_before_impact = 32
    spell.warning_frames = 10
    if facing == Direction.Left then
        spell.starting_x_offset = spell.starting_x_offset * -1
    end
    spell.x_offset = -300
    if facing == Direction.Left then
        spell.x_offset = spell.x_offset * -1
    end
    spell.y_offset = -500
    spell.x_movement = spell.x_offset / spell.frames_before_impact
    spell.y_movement = spell.y_offset / spell.frames_before_impact

    spell:set_offset(spell.x_offset,spell.y_offset)
    spell:set_hit_props(HitProps.new(
        props.damage,
        Hit.Impact,
        Element.None,
        character:get_context(),
        Drag.None)
    )
    spell.update_func = function (self)
        local tile = spell:get_current_tile()
        if self.warning_frames > 0 then
            tile:highlight(Highlight.Solid)
            self.warning_frames = self.warning_frames - 1
        end
        if self.frames_before_impact > 0 then
            if self.frames_before_impact % 3 == 0 then
                drop_trace_fx(spell)
            end
            spell.x_offset = spell.x_offset - spell.x_movement
            spell.y_offset = spell.y_offset - spell.y_movement
            spell:set_offset(spell.x_offset,spell.y_offset)
            self.frames_before_impact = self.frames_before_impact -1
        else
            tile:attack_entities(self)
            spell:delete()
            for i = 1, 3, 1 do
                spawn_impact_sparkles(character,tile)
            end
        end
    end
    spell.can_move_to_func = function ()
        return true
    end
    return spell
end

function drop_trace_fx(target_artifact)
    local fx = Battle.Artifact.new()
    local anim = target_artifact:get_animation()
    local field = target_artifact:get_field()
    local offset = target_artifact:get_offset()
    local texture = target_artifact:get_texture()
    local sprite = target_artifact:sprite()
    fx:set_facing(target_artifact:get_facing())
    fx:set_texture(texture, true)
    fx:get_animation():copy_from(anim)
    fx:get_animation():set_state(anim:get_state())
    fx:set_offset(offset.x,offset.y)
    fx:get_animation():refresh(fx:sprite())
    fx.lifetime = 255


    fx.update_func = function(self, dt)
        self.lifetime = math.max(0, self.lifetime-math.floor(dt*1000))
        self:set_color(Color.new(0, 0, 0, self.lifetime))

        if self.lifetime == 0 then 
            self:erase()
        end
    end

	local tile = target_artifact:get_current_tile()
    field:spawn(fx, tile:x(), tile:y())
end

function spawn_impact_sparkles(character,target_tile)
    local visual_artifact = Battle.Artifact.new()
    visual_artifact:set_texture(starman_effects_texture,true)
    local anim = visual_artifact:get_animation()
    local sprite = visual_artifact:sprite()
    local field = character:get_field()
    local facing = character:get_facing()
    anim:load(starman_effects_texture_animation_path)
    anim:set_state("SPARKLE")
    anim:on_complete(function()
        visual_artifact:delete()
    end)
    if facing == Direction.Left then
        position_x = position_x *-1
    end
    visual_artifact:set_facing(facing)
    visual_artifact:set_offset(math.random(-40,40),math.random(-60,0))
    anim:refresh(sprite)
    field:spawn(visual_artifact, target_tile:x(), target_tile:y())
    if math.random(1,2) == 2 then
        visual_artifact:set_facing(Direction.reverse(facing))
    end
end


return falling_star
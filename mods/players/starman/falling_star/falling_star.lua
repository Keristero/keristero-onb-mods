local battle_helpers = include('battle_helpers.lua')
local sub_folder_path = _modpath.."/falling_star/" --folder we are inside

local starman_effects_texture = Engine.load_texture(sub_folder_path .. "effects.png")
local starman_effects_texture_animation_path = sub_folder_path.. "effects.animation"
local starfall_sfx = Engine.load_audio(sub_folder_path.."starfall.ogg")

--variables that change for each version of the card
local falling_star = {
    damage=50,
    number_of_stars=3
}

function falling_star.card_create_action(user,props)
    local action = Battle.CardAction.new(user, "PLAYER_SWORD")
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)

        self:add_anim_action(2,function()
            local hilt = self:add_attachment("HILT")
            local hilt_sprite = hilt:sprite()
            hilt_sprite:set_texture(user:get_texture())
            hilt_sprite:set_layer(-2)
            hilt_sprite:enable_parent_shader(true)

            local hilt_anim = hilt:get_animation()
            hilt_anim:copy_from(user:get_animation())
            hilt_sprite:set_layer(-1)
            hilt_anim:set_state("HAND")
        end
    )
		self:add_anim_action(3,function()
            local field = user:get_field()
            local target_tile = user:get_tile(user:get_facing(),3)
            spell_falling_star(user,props,target_tile,falling_star.number_of_stars)
		end)
    end
    return action
end

function spell_falling_star(character,props,target_tile,stars_remaining)
    print('created star',stars_remaining)
    Engine.play_audio(starfall_sfx, AudioPriority.Highest)
    local field = character:get_field()
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
    spell.frames_before_spawning_next_star = 15
    spell.next_star_spawned = false
    spell.warning_frames = 20
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
        if self.frames_before_spawning_next_star > 1 then
            self.frames_before_spawning_next_star = self.frames_before_spawning_next_star - 1
        else
            if not spell.next_star_spawned and stars_remaining > 1 then
                --spawn next star with no target (will be randomized)
                spell_falling_star(character,props,nil,stars_remaining-1)
                spell.next_star_spawned = true
            end
        end
        if self.warning_frames > 0 then
            tile:highlight(Highlight.Flash)
            self.warning_frames = self.warning_frames - 1
        end
        if self.frames_before_impact > 0 then
            if self.frames_before_impact % 3 == 0 then
                battle_helpers.drop_trace_fx(spell,255)
            end
            spell.x_offset = spell.x_offset - spell.x_movement
            spell.y_offset = spell.y_offset - spell.y_movement
            spell:set_offset(spell.x_offset,spell.y_offset)
            self.frames_before_impact = self.frames_before_impact -1
        else
            tile:attack_entities(self)
            spell:delete()
            spawn_impact_sparkles(character,tile)
        end
    end
    spell.can_move_to_func = function ()
        return true
    end
    --if target tile is nil, find a random target from opposing team
    if not target_tile then
        local enemies = battle_helpers.find_all_enemies(character)
        if #enemies > 0 then
            target_tile = enemies[math.random(1,#enemies)]:get_current_tile()
        end
    end
    --if we have a target tile, spawn the star
    if target_tile then
        field:spawn(spell, target_tile:x(), target_tile:y())
    end
    return spell
end

function spawn_impact_sparkles(character,target_tile)
    for i = 1, 3, 1 do
        local x_offset = math.random(-40,40)
        local y_offset = math.random(-60,0)
        local artifact = battle_helpers.spawn_visual_artifact(character,target_tile,starman_effects_texture,starman_effects_texture_animation_path,"SPARKLE",x_offset,y_offset)
        if math.random(1,2) == 2 then
            artifact:set_facing(Direction.reverse(artifact:get_facing()))
        end
    end
end


return falling_star
local battle_helpers = include("battle_helpers.lua")

local spoutman_texture = Engine.load_texture(_folderpath .. "spoutman_spaced.png")
local spoutman_animation_path = _folderpath .. "spoutman_spaced.animation"

local sprinkler_texture = Engine.load_texture(_folderpath .. "/sprinkler/spoutman-sprinkler.png")
local sprinkler_animation_path = _folderpath .. "/sprinkler/spoutman-sprinkler.animation"

local impacts_texture = Engine.load_texture(_folderpath .. "../impacts.png")
local impacts_animation_path = _folderpath .. "../impacts.animation"

local damage_sfx = Engine.load_audio(_folderpath .. "generic_damage.ogg")

local do_nothing = function (self,dt) end

local spoutman = {
    name="DripShwr",
    description="Watr atck!\nBhnd 2row\npower-up",
    codes={"*"},
    damage=30,
    time_freeze=false,
    can_boost=true,
    element=Element.Aqua,
    card_class=CardClass.Mega
}

spoutman.card_create_action = function(user, props)
    local action = Battle.CardAction.new(user, "PLAYER_IDLE")

    action:set_lockout(make_sequence_lockout())

    action.execute_func = function(self, user)
        local actor = self:get_actor()
        local field = actor:get_field()
        local team = actor:get_team()
        local current_tile = actor:get_current_tile()
        local target_tile = nil
        local facing = user:get_facing()

        local spoutman_spin_up_frames = 36
        local spoutman_spin_cooldown_frames = 2
        local spin_frames_before_rotation = 10
        local do_sprinkler_attack = true

        local steps = {}
        local step_count = 5
        for i = 1, step_count, 1 do
            steps[#steps+1] = Battle.Step.new()
        end

        local hitprops = HitProps.new(
            spoutman.damage,
            Hit.Impact | Hit.Flash,
            Element.Aqua,
            actor:get_context(),
            Drag.None
        )

        local set_actor_visibility = function (actor,visible)
            actor:toggle_hitbox(visible)
            if visible then
                actor:reveal()
            else
                actor:hide()
            end
        end

        --Hide the actor and create the spoutman artifact
        set_actor_visibility(actor,false)
        action.spoutman_artifact = Battle.Artifact.new()
        action.spoutman_artifact:set_texture(spoutman_texture, true)
        action.spoutman_artifact:set_facing(facing)
        local anim = action.spoutman_artifact:get_animation()
        field:spawn(action.spoutman_artifact,current_tile:x(),current_tile:y())
        anim:load(spoutman_animation_path)

        steps[1].update_func = function(self, dt)
            --start leave animation
            anim:set_state("LEAVE")
            anim:set_playback(Playback.Once)
            anim:on_frame(3,function ()
                --cancel the leave animation early to go into a spin
                anim:set_state("SPRINKLER_SPIN")
                anim:set_playback(Playback.Loop)
            end)
            steps[1].update_func = function (self,dt)
                if spoutman_spin_up_frames > 0 then
                    spoutman_spin_up_frames = spoutman_spin_up_frames - 1
                    return
                end
                self:complete_step()
            end
        end

        steps[2].update_func = function(self, dt)
            --check if we can warp 3 tiles ahead
            target_tile = current_tile:get_tile(facing,3)
            if not target_tile:is_walkable() then
                do_sprinkler_attack = false
            end
            if do_sprinkler_attack then
                --move to target tile
                local distant_tile_offset = 3*80
                if facing == Direction.Left then
                    distant_tile_offset = distant_tile_offset *-1
                end
                actor:set_offset(distant_tile_offset,0)
                target_tile:add_entity(action.spoutman_artifact)
                current_tile:remove_entity_by_id(action.spoutman_artifact:get_id())
            end
            self:complete_step()
            steps[2].update_func = do_nothing
        end

        steps[3].update_func = function(self, dt)
            --spin and deal damage
            anim:set_state("SPRINKLER_SPIN")
            anim:set_playback(Playback.Loop)

            local frames_before_rotate = 0
            local direction_index = 0 --start at 0 because we immediately increment it to 1
            local flip_directions = false
            if facing == Direction.Left then
                flip_directions = true
            end
            local last_index = 9
            local attack_directions = {
                Direction.Right,
                Direction.UpRight,
                Direction.Up,
                Direction.UpLeft,
                Direction.Left,
                Direction.DownLeft,
                Direction.Down,
                Direction.DownRight,
            }

            action.sprinkler_artifact = Battle.Artifact.new()
            action.sprinkler_artifact:set_texture(sprinkler_texture, true)
            action.sprinkler_artifact:set_facing(facing)
            local sprinkler_anim = action.sprinkler_artifact:get_animation()
            sprinkler_anim:set_state(""..(direction_index % 4))
            field:spawn(action.sprinkler_artifact,target_tile:x(),target_tile:y())
            sprinkler_anim:load(sprinkler_animation_path)

            steps[3].update_func = function (self,dt)
                if frames_before_rotate > 1 then
                    frames_before_rotate = frames_before_rotate - 1
                else
                    direction_index = direction_index + 1
                    if direction_index <= last_index then
                        sprinkler_anim:set_state(""..((direction_index-1) % 4))
                    else
                        if action.sprinkler_artifact then
                            action.sprinkler_artifact:erase()
                            action.sprinkler_artifact = nil
                            steps[3].update_func = function (self,dt)
                                --keep spinning spoutman for a few frames
                                if spoutman_spin_cooldown_frames > 0 then
                                    spoutman_spin_cooldown_frames = spoutman_spin_cooldown_frames - 1
                                    return
                                end
                                self:complete_step()
                            end
                        end
                        return
                    end
                    frames_before_rotate = spin_frames_before_rotation
                    local current_direction = attack_directions[((direction_index-1) % 8)+1]
                    local opposite_dir = Direction.reverse(current_direction)
                    if flip_directions then
                        current_direction = Direction.flip_x(current_direction)
                        opposite_dir = Direction.flip_x(opposite_dir)
                    end
                    local tile_a = target_tile:get_tile(current_direction,1)
                    local tile_b = target_tile:get_tile(opposite_dir,1)
                    local damage_spell_a = create_damage_spell(team,hitprops,11)
                    field:spawn(damage_spell_a,tile_a:x(),tile_a:y())
                    local damage_spell_b = create_damage_spell(team,hitprops,11)
                    field:spawn(damage_spell_b,tile_b:x(),tile_b:y())
                end
            end
        end

        steps[4].update_func = function(self, dt)
            --return to original tile
            print('returning to original pos')
            anim:set_state("LEAVE")
            anim:on_complete(function()
                --move back to original tile tile
                actor:set_offset(0,0)
                current_tile:add_entity(action.spoutman_artifact)
                target_tile:remove_entity_by_id(action.spoutman_artifact:get_id())
                anim:set_state("APPEAR")
                anim:on_complete(function()
                    self:complete_step()
                end)
            end)
            steps[4].update_func = do_nothing
        end

        steps[5].update_func = function(self, dt)
            --return to original tile
            print('remove artifact and clean up')
            set_actor_visibility(actor,true)
            current_tile:remove_entity_by_id(action.spoutman_artifact:get_id())
            self:complete_step()
        end

        for index, step in ipairs(steps) do
            self:add_step(step)
        end
    end

    return action
end

function create_damage_spell(team,hitprops,lingering_frames)
    local spell = Battle.Spell.new(team)
    spell:set_hit_props(hitprops)
    spell.lingering_frames = lingering_frames
    spell:highlight_tile(Highlight.Solid)
    spell.update_func = function(self, dt) 
        self:get_current_tile():attack_entities(self)
        if spell.lingering_frames > 0 then
            spell.lingering_frames = spell.lingering_frames - 1
            return
        end
        self:erase()
    end
    spell.collision_func = function(self)
        Engine.play_audio(damage_sfx,AudioPriority.High)
        battle_helpers.spawn_visual_artifact(spell, self:get_current_tile(), impacts_texture,impacts_animation_path, "1", 0, 0)
    end
    return spell
end

return spoutman
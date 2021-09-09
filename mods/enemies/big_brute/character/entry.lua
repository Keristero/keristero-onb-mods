local character_info = {name = "BigBrute", hp = 120,height=60}
local debug = false
function debug_print(text)
    if debug then
        print("[bigbrute] " .. text)
    end
end

function package_init(self)
    debug_print("package_init called")
    -- Required function, main package information

    -- Load character resources
    self.texture = Engine.load_texture(_modpath .. "battle.png")
    self.animation = self:get_animation()
    self.animation:load(_modpath .. "battle.animation")

    -- Load extra resources
    fire_tower_animation_path = _modpath .. "firetower.animation"
    fire_tower_texture_path = _modpath .. "firetower.png"
    fire_tower_texture = Engine.load_texture(fire_tower_texture_path)
    fire_tower_sound = Engine.load_audio(_modpath.."firetower.ogg")

    teleport_animation_path = _modpath .. "teleport.animation"
    teleport_texture_path = _modpath .. "teleport.png"
    teleport_texture = Engine.load_texture(teleport_texture_path)

    impacts_animation_path = _modpath .. "impacts.animation"
    impacts_texture_path = _modpath .. "impacts.png"
    impacts_texture = Engine.load_texture(impacts_texture_path)


    -- Set up character meta
    self:set_name(character_info.name)
    self:set_health(character_info.hp)
    self:set_texture(self.texture, true)
    self:set_height(character_info.height)
    self:share_tile(false)
    self:set_explosion_behavior(4, 1.0, false)
    self:set_position(0, 0)

    -- keep track of spells that can be interrupted
    self.next_spell_id = 0
    self.interruptable_spells = {}

    -- Initial state
    self.animation:set_state("IDLE")
    self.animation:set_playback(Playback.Loop)
    self.ai_state = "spawning"
    self.ai_timer = 0
    self.ai_jumps = 0
    self.ai_target_jumps = math.random(4, 5)
    self.frames_between_jumps = 40

    self.update_func = function(self, dt)
        local character = self
        local character_facing = character:get_facing()
        -- debug_print("original update_func called: "..character.ai_state)
        if character.ai_state == "idle" then
            character.ai_timer = character.ai_timer + 1
            if character.ai_timer > character.frames_between_jumps then
                local is_attacking = false
                character.ai_jumps = character.ai_jumps + 1
                if character.ai_jumps >= character.ai_target_jumps then
                    is_attacking = true
                    character.ai_state = "attacking"
                end
                big_brute_teleport(character, is_attacking)
                if is_attacking then
                    local action = action_beast_breath(character)
                    character:card_action_event(action, ActionOrder.Voluntary)
                    action.action_end_func = function()
                        character.ai_state = "idle"
                        character.ai_jumps = 0
                        self.ai_target_jumps = math.random(4, 5)
                    end
                end
                character.ai_timer = 0
            end
        end
    end
    self.battle_start_func = function(self)
        self.ai_state = "idle"
        debug_print("battle_start_func called")
    end
    self.battle_end_func = function(self)
        debug_print("battle_end_func called")
    end
    self.on_spawn_func = function(self, spawn_tile)
        debug_print("on_spawn_func called")
    end
    self.can_move_to_func = function(tile)
        debug_print("can_move_to_func called")
        return is_tile_free_for_movement(tile,self)
    end
    self.delete_func = function(self) debug_print("delete_func called") end
    self:register_status_callback(Hit.Flinch,function ()
        debug_print("Got flinched!")
        if self.interruptable_action then
            debug_print("Ending interruptable_action")
            self.interruptable_action:end_action()
            self.interruptable_action = nil
        end
        for spell_id, spell in pairs(self.interruptable_spells) do
            debug_print("interruped spell"..spell_id)
            spell:remove()
            self.interruptable_spells[spell_id] = nil
        end
    end)
end

function big_brute_teleport(character, is_attacking)
    local field = character:get_field()
    local user_team = character:get_team()
    local target_list = field:find_characters(function(other_character)
            return other_character:get_team() ~= user_team
    end)
    if #target_list == 0 then
        debug_print("No targets found!")
        return
    end
    local target_character = target_list[1]
    local target_character_tile = target_character:get_current_tile()

    local target_tile = nil
    allowed_movement_tiles = field:find_tiles(function(other_tile)
        if not is_tile_free_for_movement(other_tile,character) then
            return false
        end
        if other_tile:is_reserved({character}) then
            return false
        end
        if target_character_tile:y() == other_tile:y() then
            return is_attacking
        else
            return not is_attacking
        end
        return true
    end)
    if #allowed_movement_tiles > 0 then
        target_tile = allowed_movement_tiles[math.random(#allowed_movement_tiles)]
    else
        target_tile = character:get_current_tile()
    end
    local teleport_action = action_teleport(character,target_tile)
    target_tile:reserve_entity_by_id(character:get_id())
    teleport_action.action_end_func = function(self)
        debug_print('action end func')
        local departure_tile = character:get_current_tile()
        spawn_visual_artifact(departure_tile,character,teleport_texture,teleport_animation_path,teleport_action.teleport_size.."_TELEPORT_FROM",0,-character_info.height)
        debug_print('target tile '..target_tile:x()..' '..target_tile:y())
        character:teleport(target_tile, ActionOrder.Immediate)
    end
    character:card_action_event(teleport_action, ActionOrder.Immediate)
end

function is_tile_free_for_movement(tile,character)
    --Basic check to see if a tile is suitable for a chracter of a team to move to
    if tile:get_team() ~= character:get_team() then return false end
    if not tile:is_walkable() then return false end
    local occupants = tile:find_characters(function(other_character)
        return true
    end)
    if #occupants > 0 then 
        return false
    end
    return true
end

function spawn_visual_artifact(tile,character,texture,animation_path,animation_state,position_x,position_y)
    local field = character:get_field()
    local visual_artifact = Battle.Artifact.new(character:get_team())
    visual_artifact:set_texture(texture,true)
    local anim = visual_artifact:get_animation()
    anim:load(animation_path)
    anim:set_state(animation_state)
    anim:on_complete(function()
        visual_artifact:delete()
    end)
    visual_artifact:sprite():set_position(position_x,position_y)
    field:spawn(visual_artifact, tile:x(), tile:y())
end

function action_teleport(character, target_tile)
    local action_name = "teleport"
    debug_print('action ' .. action_name)

    local action = Battle.CardAction.new(character, "IDLE")
    action:set_lockout(make_sequence_lockout())

    action.teleport_size = "SMALL"
    if character_info.height > 60 then
        action.teleport_size = "BIG"
    elseif character_info.height > 40 then
        action.teleport_size = "MEDIUM"
    end

    action.execute_func = function(self)
        debug_print('executing action ' .. action_name)
        local step1 = Battle.Step.new()
        local step2 = Battle.Step.new()
        local actor = self:get_actor()

        --add a reference to this function to indicate that it can be canceled
        character.interruptable_action = action

        action.pre_teleport_ms = 32/1000
        action.elapsed = 0
        action.arrival_artifact_created = false
        action.departure_artifact_created = false

        step1.update_func = function(self, dt)
            debug_print('action ' .. action_name .. ' step 1 update')
            if not action.arrival_artifact_created then
                spawn_visual_artifact(target_tile,character,teleport_texture,teleport_animation_path,action.teleport_size.."_TELEPORT_TO",0,-character_info.height)
                action.arrival_artifact_created = true
            end
            if action.elapsed <= action.pre_teleport_ms then
                action.elapsed = action.elapsed + dt
                return
            end
            character.interruptable_action = nil
            self:complete_step()
            debug_print('action ' .. action_name .. ' step 1 complete')
        end
        action:add_step(step1)
    end
    return action
end

function action_beast_breath(character)
    local action_name = "beast breath"
    debug_print('action ' .. action_name)

    local action = Battle.CardAction.new(character, "IDLE")
    action:set_lockout(make_sequence_lockout())

    action.execute_func = function(self)
        debug_print('executing action ' .. action_name)
        local step1 = Battle.Step.new()
        local step2 = Battle.Step.new()

        --add a reference to this function to indicate that it can be canceled
        character.interruptable_action = action
        local actor = self:get_actor()
        action.pre_attack_anim_started = false
        action.attack_anim_started = false
        action.pre_attack_time_counter = 0
        action.pre_attack_time = 0.7
        action.attack_time_counter = 0
        action.attack_time = 1.0
        action.pre_attack_counter_time = 0.2
        action.counter_enabled = false


        step1.update_func = function(self, dt)
            -- debug_print('action '..action_name..' step 1')
            if not action.pre_attack_anim_started then
                local anim = actor:get_animation()
                anim:set_state("PRE_ATTACK")
                anim:set_playback(Playback.Loop)
                action.pre_attack_anim_started = true
                local direction = actor:get_facing()
                local t1 = actor:get_tile(direction, 1)
                local t2 = actor:get_tile(direction, 2)
                local t3 = actor:get_tile(direction, 3)
                if t1 then
                    fire_tower_spell(character, 50, 0.5, action.pre_attack_time, t1:x(), t1:y())
                end
                if t2 then
                    local x = t2:x()
                    local y = t2:y()
                    fire_tower_spell(character, 50, 0.5, action.pre_attack_time, x, y - 1)
                    fire_tower_spell(character, 50, 0.5, action.pre_attack_time, x, y)
                    fire_tower_spell(character, 50, 0.5, action.pre_attack_time, x, y + 1)
                end
                if t3 then
                    fire_tower_spell(character, 50, 0.5, action.pre_attack_time, t3:x(), t3:y())
                end

            end
            if action.pre_attack_time_counter < action.pre_attack_time then
                action.pre_attack_time_counter = action.pre_attack_time_counter + dt
                if action.pre_attack_time_counter <= action.pre_attack_time - action.pre_attack_counter_time and not action.counter_enabled then
                    actor:toggle_counter(true)
                end
            else
                Engine.play_audio(fire_tower_sound, AudioPriority.Highest)
                actor:toggle_counter(false)
                character.interruptable_action = nil
                self:complete_step()
            end
        end

        step2.update_func = function(self, dt)
            -- debug_print('action '..action_name..' step 2')
            if not action.attack_anim_started then
                local anim = actor:get_animation()
                anim:set_state("ATTACK")
                anim:set_playback(Playback.Loop)
                action.attack_anim_started = true
            end
            if action.attack_time_counter < action.attack_time then
                action.attack_time_counter = action.attack_time_counter + dt
            else
                debug_print('action ' .. action_name .. ' step 2 complete')
                local anim = actor:get_animation()
                anim:set_state("IDLE")
                anim:set_playback(Playback.Loop)
                self:complete_step()
            end
        end

        self:add_step(step1)
        self:add_step(step2)
    end
    return action
end

function fire_tower_spell(user, damage, duration, warning_duration, x, y)
    local field = user:get_field()
    local target_tile = field:tile_at(x,y)
    if target_tile:is_edge() then
        return
    end
    local spell = Battle.Spell.new(user:get_team())
    spell:set_texture(fire_tower_texture, true)
    spell:highlight_tile(Highlight.Flash)
    spell:set_hit_props(make_hit_props(damage, Hit.Impact | Hit.Flash | Hit.Flinch,
                                       Element.Fire, user:get_id(),
                                       drag(Direction.Right, 0)))
    spell.elapsed = 0
    spell.current_state = 1
    spell.state_changed = false

    spell.duration_states = {warning_duration, 0.15, duration, 0.15, 999}

    spell.attack_func = function(self, other)
        local tile = self:get_current_tile()
        --TODO replace this with volcano effect (gotta make the animation)
        spawn_visual_artifact(tile,self,impacts_texture,impacts_animation_path,"VOLCANO",0,0)
    end

    spell.update_func = function(self, delta_time)
        self.elapsed = self.elapsed + delta_time
        if self.elapsed >= self.duration_states[spell.current_state] then
            self.current_state = self.current_state + 1
            self.state_changed = true
            self.elapsed = 0
        end
        if self.state_changed then
            local anim = self:get_animation()
            if self.current_state == 2 then
                --Spell can no longer be interrupted
                user.interruptable_spells[spell.user_spell_id] = nil
                spell:sprite():show()
                anim:set_state("START")
                anim:set_playback(Playback.Once)
                anim:on_complete(function()
                    self.current_state = self.current_state + 1
                    self.state_changed = true
                    self.elapsed = 0
                end)
                self:highlight_tile(Highlight.None)
            end
            if self.current_state == 3 then
                anim:set_state("LOOP")
                anim:set_playback(Playback.Loop)
            end
            if self.current_state == 4 then
                anim:set_state("END")
                anim:set_playback(Playback.Once)
                anim:on_complete(function()
                    self.current_state = self.current_state + 1
                    self.state_changed = true
                    self.elapsed = 0
                end)
            end
            if self.current_state == 5 then
                debug_print('spell complete')
                spell:delete()
            end
            self.state_changed = false
        end
        if self.current_state >= 2 then
            -- if we are in damaging frames
            local current_tile = self:get_current_tile()
            current_tile:attack_entities(self)
        end
    end

    local anim = spell:get_animation()
    spell:sprite():hide()
    anim:load(fire_tower_animation_path)
    anim:set_state("START")

    field:spawn(spell, x, y)
    -- use direct hit / back of field animation

    --Add spell to list of spells that can be interrupted and removed on flinch
    debug_print('next spell id='..user.next_spell_id)
    user.interruptable_spells[user.next_spell_id] = spell
    spell.user_spell_id = user.next_spell_id
    user.next_spell_id = user.next_spell_id + 1
    return spell
end

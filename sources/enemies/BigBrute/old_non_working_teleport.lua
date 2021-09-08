local character_info = {name = "BigBrute", hp = 120,height=60}

function debug_print(text) print("[bigbrute] " .. text) end

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

    teleport_animation_path = _modpath .. "teleport.animation"
    teleport_texture_path = _modpath .. "teleport.png"
    teleport_texture = Engine.load_texture(teleport_texture_path)

    -- Set up character meta
    self:set_name(character_info.name)
    self:set_health(character_info.hp)
    self:set_texture(self.texture, true)
    self:set_height(character_info.height)
    self:share_tile(false)
    self:set_explosion_behavior(4, 1.0, false)
    self:set_position(0, 0)

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
        return true
    end
    self.delete_func = function(self) debug_print("delete_func called") end
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
        if other_tile:get_team() ~= user_team then return false end
        if not other_tile:is_walkable() then return false end
        local occupants = other_tile:find_characters(function(other_character)
            return true
        end)
        if #occupants > 0 then return false end
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
        character:teleport(target_tile, ActionOrder.Immediate)
    end
    character:card_action_event(teleport_action, ActionOrder.Immediate)
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

    local teleport_size = "SMALL"
    if character_info.height > 60 then
        teleport_size = "BIG"
    elseif character_info.height > 40 then
        teleport_size = "MEDIUM"
    end

    action.execute_func = function(self)
        debug_print('executing action ' .. action_name)
        local step1 = Battle.Step.new()
        local step2 = Battle.Step.new()
        local actor = self:get_actor()

        action.pre_teleport_ms = 32/1000
        action.elapsed = 0
        action.arrival_artifact_created = false
        action.departure_artifact_created = false

        step1.update_func = function(self, dt)
            debug_print('action ' .. action_name .. ' step 1 update')
            if not action.arrival_artifact_created then
                spawn_visual_artifact(target_tile,character,teleport_texture,teleport_animation_path,teleport_size.."_TELEPORT_TO",0,-character_info.height)
                action.arrival_artifact_created = true
            end
            if action.elapsed <= action.pre_teleport_ms then
                debug_print('elapsed ' .. action.elapsed)
                action.elapsed = action.elapsed + dt
                return
            end
            self:complete_step()
            debug_print('action ' .. action_name .. ' step 1 complete')
        end

        step2.update_func = function(self, dt)
            debug_print('action ' .. action_name .. ' step 2 update')
            local departure_tile = character:get_current_tile()
            if not action.departure_artifact_created then
                spawn_visual_artifact(departure_tile,character,teleport_texture,teleport_animation_path,teleport_size.."_TELEPORT_FROM",0,-character_info.height)
                action.departure_artifact_created = true
            end
            print('target tile '..target_tile:x()..' '..target_tile:y())
            actor:teleport(target_tile, ActionOrder.Immediate)
            self:complete_step()
            debug_print('action ' .. action_name .. ' step 2 complete')
        end
        action:add_step(step1)
        action:add_step(step2)
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

        local actor = self:get_actor()
        action.pre_attack_anim_started = false
        action.attack_anim_started = false
        action.pre_attack_time_counter = 0
        action.pre_attack_time = 0.7
        action.attack_time_counter = 0
        action.attack_time = 1.0

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
                    fire_tower_spell(actor, 50, 0.5, action.pre_attack_time, t1:x(), t1:y())
                end
                if t2 then
                    local x = t2:x()
                    local y = t2:y()
                    fire_tower_spell(actor, 50, 0.5, action.pre_attack_time, x, y - 1)
                    fire_tower_spell(actor, 50, 0.5, action.pre_attack_time, x, y)
                    fire_tower_spell(actor, 50, 0.5, action.pre_attack_time, x, y + 1)
                end
                if t3 then
                    fire_tower_spell(actor, 50, 0.5, action.pre_attack_time, t3:x(), t3:y())
                end

            end
            if action.pre_attack_time_counter < action.pre_attack_time then
                action.pre_attack_time_counter =
                    action.pre_attack_time_counter + dt
            else
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
    spell:set_hit_props(make_hit_props(damage, Hit.Impact | Hit.Flinch,
                                       Element.Fire, user:get_id(),
                                       drag(Direction.Right, 0)))
    spell.elapsed = 0
    spell.current_state = 1
    spell.state_changed = false

    spell.duration_states = {warning_duration, 0.15, duration, 0.15, 999}

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
end


local character_info = {
    name = "RickAstley",
    hp = 499,
    height = 120
}

enraged = false

function debug_print(text)
    print("[RickAstley] "..text)
end

function package_init(self)
    debug_print("package_init called")
    --Required function, main package information

    --Load character resources
	self.texture = Engine.load_texture(_modpath.."battle.png")
	self.animation = self:get_animation()
	self.animation:load(_modpath.."battle.animation")

    --Load extra resources
    fire_tower_animation_path = _modpath.."firetower.animation"
    fire_tower_texture_path = _modpath.."firetower.png"
    fire_tower_texture = Engine.load_texture(fire_tower_texture_path)
    fire_tower_sound = Engine.load_audio(_modpath.."firetower.ogg")

    impacts_animation_path = _modpath .. "impacts.animation"
    impacts_texture_path = _modpath .. "impacts.png"
    impacts_texture = Engine.load_texture(impacts_texture_path)

    --Set up character meta
    self:set_name(character_info.name)
    self:set_health(character_info.hp)
    self:set_texture(self.texture, true)
    self:set_height(character_info.height)
    self:share_tile(false)
    self:set_explosion_behavior(32, 1.0, false)
    self:set_position(0, 0)

    --Initial state
    self.animation:set_state("IDLE")
    self.animation:set_playback(Playback.Loop)
    self.ai_state = "spawning"
    self.ai_timer = 0
    self.ai_jumps = 0
    self.combo_length = 0
    self.ai_target_jumps = math.random(2,3)
    self.frames_between_jumps = 10
    self.frames_before_attack_start = 2
    
    enraged = false

    self.update_func = function (self,dt)
        local character = self
        local character_facing = character:get_facing()
        if character:get_health() < 500 then
            enraged = true
        end
        character.ai_timer = character.ai_timer + 1
        --debug_print("original update_func called: "..character.ai_state)
        if character.ai_state == "idle" then
            if character.ai_timer > character.frames_between_jumps then
                local moving_to_attack_position = false
                character.ai_jumps = character.ai_jumps + 1
                if character.ai_jumps >= character.ai_target_jumps then
                    moving_to_attack_position = true
                    character.ai_state = "preparing_attack"
                end
                big_brute_teleport(character,moving_to_attack_position)
                character.ai_timer = 0
            end
        end
        if character.ai_state == "preparing_attack" then
            if character.ai_timer > character.frames_before_attack_start then
                local action = action_random_attack(character)
                character:card_action_event(action,ActionOrder.Voluntary)
                character.ai_state = "attacking"
                action.action_end_func = function ()
                    character.ai_timer = 0
                    if enraged and character.combo_length < 3 then
                        character.ai_state = "preparing_attack"
                        character.combo_length = character.combo_length + 1
                    else
                        character.combo_length = 0
                        character.ai_state = "idle"
                        character.ai_jumps = 0
                        self.ai_target_jumps = math.random(4,5)
                    end
                end
            end
        end
    end
    self.battle_start_func = function (self)
        self.ai_state = "idle"
        debug_print("battle_start_func called")
    end
    self.battle_end_func = function (self)
        debug_print("battle_end_func called")
    end
    self.on_spawn_func = function (self, spawn_tile) 
        debug_print("on_spawn_func called")
   end
    self.can_move_to_func = function (tile)
        debug_print("can_move_to_func called")
        local x = tile:x()
        local y = tile:y()
        local field = self:get_field()
        if x == 0 or x >= field:width()+1 or y == 0 or y >= field:height()+1 then
            return false
        end
        if not tile:is_walkable() then
            return false
        end
        return true
    end
    self.delete_func = function (self)
        debug_print("delete_func called")
    end
end


function big_brute_teleport(character,moving_to_attack_position)
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
    local target_character_tile =  target_character:get_current_tile()
    
    local target_tile = nil
    allowed_movement_tiles = field:find_tiles(function(other_tile)
        if other_tile:get_team() ~= user_team then
            return false
        end
        if not other_tile:is_walkable() then
            return false
        end
        local occupants = other_tile:find_characters(function(other_character) return true end)
        if #occupants > 0 then
            return false
        end
        if target_character_tile:y() == other_tile:y() then
            return true
        else
            return not moving_to_attack_position
        end
        return true
    end)
    if #allowed_movement_tiles > 0 then
        target_tile = allowed_movement_tiles[math.random(#allowed_movement_tiles)]
    else
        target_tile = character:get_current_tile()
    end
    character:teleport(target_tile,ActionOrder.Immediate)
    return target_tile
end

function action_random_attack(character)
    local attack_actions = {action_fire_tower_line,action_fire_tower_random}
    local chosen_one = attack_actions[math.random(#attack_actions)]
    return chosen_one(character)
end

function action_fire_tower_line(character)
    local direction = character:get_facing()
    local target_tiles = {}
    for i = 1, 9, 1 do
        local t1 = character:get_tile(direction,i)
        if t1 then
            target_tiles[#target_tiles+1] = t1
        end
    end
    local attack_action = action_fire_tower_target_tiles(character,target_tiles,200)
    return attack_action
end

function action_fire_tower_random(character)
    local direction = character:get_facing()
    local field = character:get_field()
    local target_tiles = {}
    local current_tile_x = character:get_current_tile():x()
    for x = 0, current_tile_x, 1 do
        for y = 0, 4, 1 do
            if math.random(1,3) == 3 then
                local t1 = field:tile_at(x,y)
                if t1 then
                    target_tiles[#target_tiles+1] = t1
                end
            end
        end
    end
    local attack_action = action_fire_tower_target_tiles(character,target_tiles,200)
    return attack_action
end

function action_fire_tower_target_tiles(character,target_tiles,damage)
    local action_name = "fire_tower_target_tiles"
    debug_print('action ' .. action_name)

    local action = Battle.CardAction.new(character, "ATTACK")
    action:set_lockout(make_sequence_lockout())

    action.execute_func = function(self)
        debug_print('executing action ' .. action_name)
        local step1 = Battle.Step.new()
        local step2 = Battle.Step.new()

        --add a reference to this function to indicate that it can be canceled
        local actor = self:get_actor()
        action.pre_attack_anim_started = false
        action.attack_anim_started = false
        action.pre_attack_time_counter = 0
        action.pre_attack_time = 0.5
        action.attack_time_counter = 0
        action.attack_time = 0.5
        action.pre_attack_counter_time = 0.1
        action.counter_enabled = false

        action.warning_toggle_frames = 4
        action.warning_toggle = false
        action.warning_toggle_frames_elapsed = 0
        action.target_tiles = target_tiles

        step1.update_func = function(self, dt)
            -- debug_print('action '..action_name..' step 1')
            if not action.pre_attack_anim_started then
                local anim = actor:get_animation()
                anim:set_state("ATTACK")
                anim:set_playback(Playback.Once)
                action.pre_attack_anim_started = true
            end
            if action.pre_attack_time_counter < action.pre_attack_time then
                action.pre_attack_time_counter = action.pre_attack_time_counter + dt

                --flash target tiles
                for index, target_tile in ipairs(action.target_tiles) do
                    if action.warning_toggle then
                        target_tile:highlight(Highlight.Solid)
                    end
                end
                --cycle flashing
                action.warning_toggle_frames_elapsed = action.warning_toggle_frames_elapsed + 1
                if action.warning_toggle_frames_elapsed >= action.warning_toggle_frames then
                    action.warning_toggle_frames_elapsed = 0
                    action.warning_toggle = not action.warning_toggle
                end

                --enable counter frames at certain time before attack
                if action.pre_attack_time_counter <= action.pre_attack_time - action.pre_attack_counter_time and not action.counter_enabled then
                    actor:toggle_counter(true)
                end
            else
                actor:toggle_counter(false)
                self:complete_step()
            end
        end

        step2.update_func = function(self, dt)
            -- debug_print('action '..action_name..' step 2')
            if not action.attack_anim_started then
                action.attack_anim_started = true
                Engine.play_audio(fire_tower_sound, AudioPriority.Highest)

                --Do attacking
                for index, target_tile in ipairs(action.target_tiles) do
                    fire_tower_spell(character, damage, 0.5, target_tile:x(), target_tile:y())
                end
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

function fire_tower_spell(user, damage, duration, x, y)
    local field = user:get_field()
    local target_tile = field:tile_at(x,y)
    if target_tile:is_edge() then
        return
    end
    local spell = Battle.Spell.new(user:get_team())
    spell:set_texture(fire_tower_texture, true)
    spell:set_hit_props(make_hit_props(damage, Hit.Impact | Hit.Flash | Hit.Flinch,
                                       Element.Fire, user:get_id(),
                                       drag(Direction.Right, 0)))
    spell.elapsed = 0
    spell.current_state = 1
    spell.state_changed = true

    spell.duration_states = {999, duration, 999, 999}

    spell.attack_func = function(self, other)
        local tile = self:get_current_tile()
        --TODO replace this with volcano effect (gotta make the animation)
        spawn_visual_artifact(tile,self,impacts_texture,impacts_animation_path,"VOLCANO",0,0)
    end

    spell.update_func = function(self, delta_time)
        -- damage entities
        local current_tile = self:get_current_tile()
        current_tile:attack_entities(self)
        -- update elapsed time
        self.elapsed = self.elapsed + delta_time
        if self.elapsed >= self.duration_states[spell.current_state] then
            self.current_state = self.current_state + 1
            self.state_changed = true
            self.elapsed = 0
        end
        --on state change
        if self.state_changed then
            local anim = self:get_animation()
            if self.current_state == 1 then
                anim:set_state("START")
                anim:set_playback(Playback.Once)
                anim:on_complete(function()
                    self.current_state = self.current_state + 1
                    self.state_changed = true
                    self.elapsed = 0
                end)
            end
            if self.current_state == 2 then
                anim:set_state("LOOP")
                anim:set_playback(Playback.Loop)
            end
            if self.current_state == 3 then
                anim:set_state("END")
                anim:set_playback(Playback.Once)
                anim:on_complete(function()
                    self.current_state = self.current_state + 1
                    self.state_changed = true
                    self.elapsed = 0
                end)
            end
            if self.current_state == 4 then
                spell:delete()
            end
            self.state_changed = false
        end
    end

    local anim = spell:get_animation()
    anim:load(fire_tower_animation_path)
    anim:set_state("START")
    field:spawn(spell, x, y)
    return spell
end

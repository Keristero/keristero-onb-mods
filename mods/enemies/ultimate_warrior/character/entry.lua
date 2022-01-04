local battle_helpers = include("battle_helpers.lua")

local character_info = {
    name = "RickAstley",
    hp = 1337,
    height = 120
}

function debug_print(text)
    --print("[RickAstley] "..text)
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

    say_goodbye_sound = Engine.load_audio(_modpath.."special1.ogg")
    tell_you_how_im_feeling_sound = Engine.load_audio(_modpath.."enrage.ogg")
    deathcry_sound = Engine.load_audio(_modpath.."deathcry.ogg")

    impacts_animation_path = _modpath .. "impacts.animation"
    impacts_texture_path = _modpath .. "impacts.png"
    impacts_texture = Engine.load_texture(impacts_texture_path)

    --Set up character meta
    self:set_name(character_info.name)
    self:set_health(character_info.hp)
    self:set_texture(self.texture, true)
    self:set_height(character_info.height)
    self:share_tile(false)
    self:set_explosion_behavior(32, 1.0, true)
    self:set_offset(0, 0)

    --Initial state
    self.animation:set_state("IDLE")
    self.animation:set_playback(Playback.Loop)
    self.ai_state = "spawning"
    self.ai_timer = 0
    self.ai_jumps = 0
    self.ai_target_jumps = math.random(2,3)
    self.frames_between_jumps = 10
    self.frames_before_attack_start = 2
    self.seconds_since_attack_landed = 2
    self.combo_length = 0
    
    self.enraged = false

    self.update_func = function (self,dt)
        local character = self
        local character_facing = character:get_facing()
        if character.enraged then
            character:set_color(Color.new( 255, 0, 0, 255 ) )
        end
        character.seconds_since_attack_landed = character.seconds_since_attack_landed + dt 
        debug_print(character.seconds_since_attack_landed)
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
                    if character.enraged and character.combo_length <= 3 then
                        character.ai_state = "preparing_attack"
                        character.combo_length = character.combo_length + 1
                    else
                        character.combo_length = 0
                        character.ai_state = "idle"
                        character.ai_jumps = 0
                        self.ai_target_jumps = math.random(4,8)
                    end
                end
            end
        end
        if character.ai_state == "attacking" and character.ai_timer > 300 then
            debug_print("character was stuck attacking, forced back to idle (action interruptions are not being handled correctly)")
            character.ai_state = "idle"
            character.ai_timer = 0
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
        Engine.play_audio(deathcry_sound, AudioPriority.Highest)
    end
    self.interrupted_callback = function()
        debug_print("interrupted_callback called")
        self.ai_state = "idle"
    end
    self:register_status_callback(Hit.Freeze | Hit.Flinch | Hit.Stun | Hit.Drag | Hit.Bubble,self.interrupted_callback)
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
    local attack_actions = {action_fire_tower_random}
    local field = character:get_field()
    if not character.enraged then
        attack_actions[#attack_actions+1] = action_fire_tower_line
    end

    if character.seconds_since_attack_landed > 2 then
        --Try doing enrage attack if we have not already and we are blelow hp threshhold
        if character:get_health() < 500 and not character.enraged then
            attack_actions[#attack_actions+1] = action_enrage
        end
        --Try adding execute attack to the pool of attacks, if there is an applicible target
        local found_target = false
        local targets = field:find_nearest_characters(character,function(other_character)
            if other_character:get_id() == character:get_id() then
                return false
            end
            if not found_target and other_character:get_health() < 300 then
                found_target = true
                return true
            end
            return false
        end)
        if #targets > 0 then
            attack_actions[#attack_actions+1] = action_say_goodbye
        end
    end

    local chosen_one = attack_actions[math.random(#attack_actions)]
    return chosen_one(character)
end

function action_say_goodbye(character)
    local action_name = "say_goodbye"
    debug_print('action ' .. action_name)

    local action = Battle.CardAction.new(character, "ATTACK")
    action:set_lockout(make_sequence_lockout())
    local card_props = action:copy_metadata()
    card_props.shortname = "Never gonna"
    card_props.damage = 300
    card_props.time_freeze = true
    card_props.element = Element.Summon
    card_props.description = "Say Goodbye!"
	card_props.card_class = CardClass.Mega
    action:set_metadata(card_props)

    local field = character:get_field()

    local target_tiles = {}
    for x = 0, field:width(), 1 do
        for y = 0, field:height(), 1 do
            local t1 = field:tile_at(x,y)
            if t1 then
                target_tiles[#target_tiles+1] = t1
            end
        end
    end

    action.execute_func = function(self)
        debug_print('executing action ' .. action_name)
        local step1 = Battle.Step.new()
        local step2 = Battle.Step.new()

        --add a reference to this function to indicate that it can be canceled
        local actor = self:get_actor()
        debug_print('got actor')
        action.pre_attack_anim_started = false
        action.attack_anim_started = false
        action.pre_attack_time_counter = 0
        action.pre_attack_time = 1
        action.attack_time_counter = 0
        action.attack_time = 0.5
        action.pre_attack_counter_time = 0.1
        action.counter_enabled = false

        action.warning_toggle_frames = 4
        action.warning_toggle = false
        action.warning_toggle_frames_elapsed = 0
        action.target_tiles = target_tiles


        debug_print('setup actor')
        step1.update_func = function(self, dt)
            -- debug_print('action '..action_name..' step 1')
            if not action.pre_attack_anim_started then
                Engine.play_audio(say_goodbye_sound, AudioPriority.Highest)
                debug_print('pre attack start')
                local anim = actor:get_animation()
                anim:set_state("ATTACK")
                anim:set_playback(Playback.Once)
                action.pre_attack_anim_started = true
            end
            if action.pre_attack_time_counter < action.pre_attack_time then
                debug_print('pre attack time ticking')
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
            else
                self:complete_step()
            end
        end

        step2.update_func = function(self, dt)
            -- debug_print('action '..action_name..' step 2')
            if not action.attack_anim_started then
                action.attack_anim_started = true
                Engine.play_audio(fire_tower_sound, AudioPriority.Highest)
                character:shake_camera( 2.0, 1.0 )

                --Do attacking
                for index, target_tile in ipairs(action.target_tiles) do
                    fire_tower_spell(actor, card_props.damage, 1, target_tile:x(), target_tile:y())
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

function action_enrage(character)
    local action_name = "enrage"
    debug_print('action ' .. action_name)

    local field = character:get_field()
    local target_tiles = {}
    target_tiles[#target_tiles+1] = field:tile_at(1,1)
    target_tiles[#target_tiles+1] = field:tile_at(3,1)
    target_tiles[#target_tiles+1] = field:tile_at(1,3)
    target_tiles[#target_tiles+1] = field:tile_at(3,3)
    local new_tile_state = TileState.Volcano
    local action = action_set_tile_states(character,target_tiles,new_tile_state)

    local card_props = action:copy_metadata()
    card_props.shortname = "..!"
    card_props.damage = 0
    card_props.time_freeze = true
    card_props.element = Element.Summon
    card_props.description = "How I'm Feelin"
	card_props.card_class = CardClass.Mega
    action:set_metadata(card_props)

    return action
end

function action_set_tile_states(character,target_tiles,target_state)
    local action_name = "action_set_tile_states"
    debug_print('action ' .. action_name)

    local action = Battle.CardAction.new(character, "")
    action:set_lockout(make_sequence_lockout())
    action.target_tiles = target_tiles
    action.target_state = target_state
    action.start_delay_seconds = 4
    action.highlight_time = 0.1

    action.execute_func = function(self)
        debug_print('executing action ' .. action_name)
        local step1 = Battle.Step.new()
        local step2 = Battle.Step.new()

        --add a reference to this function to indicate that it can be canceled
        local actor = self:get_actor()
        Engine.play_audio(tell_you_how_im_feeling_sound, AudioPriority.Highest)
        character.enraged = true
        

        step1.update_func = function(self, dt)
            debug_print('action '..action_name..' step 1')
            if action.start_delay_seconds > 0 then
                action.start_delay_seconds = action.start_delay_seconds - dt
                if action.start_delay_seconds <= action.highlight_time then
                    for index, target_tile in ipairs(action.target_tiles) do
                        target_tile:highlight(Highlight.Solid)
                    end
                end
                return
            end
            self:complete_step()
        end
        step2.update_func = function(self, dt)
            debug_print('action '..action_name..' step 2')
            for index, target_tile in ipairs(action.target_tiles) do
                target_tile:set_state(action.target_state)
            end
            self:complete_step()
        end
        self:add_step(step1)
        self:add_step(step2)
    end
    return action
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
    fire_tower_delay = 0.5
    if character.enraged then
        fire_tower_delay = 0.4
    end
    local attack_action = action_fire_tower_target_tiles(character,target_tiles,200,fire_tower_delay)
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
    local fire_tower_delay = 0.5
    if character.enraged then
        fire_tower_delay = 0.4
    end
    local attack_action = action_fire_tower_target_tiles(character,target_tiles,200,fire_tower_delay)
    return attack_action
end

function action_fire_tower_target_tiles(character,target_tiles,damage,tower_delay)
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
        action.attack_anim_started = false
        action.pre_attack_time_counter = 0
        action.pre_attack_time = tower_delay
        action.attack_time_counter = 0
        action.attack_time = 0.5
        action.pre_attack_counter_time = 0.1
        action.counter_enabled = false

        action.warning_toggle_frames = 4
        action.warning_toggle = false
        action.warning_toggle_frames_elapsed = 0
        action.target_tiles = target_tiles

        local anim = actor:get_animation()
        anim:set_state("ATTACK")
        anim:set_playback(Playback.Once)

        step1.update_func = function(self, dt)
            -- debug_print('action '..action_name..' step 1')
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

function fire_tower_spell(user, damage, duration, x, y)
    local field = user:get_field()
    local target_tile = field:tile_at(x,y)
    if target_tile:is_edge() then
        return
    end
    local spell = Battle.Spell.new(user:get_team())
    spell:set_texture(fire_tower_texture, true)
    spell:set_hit_props(HitProps.new(damage, Hit.Impact | Hit.Flash | Hit.Flinch,
                                       Element.Fire, user:get_context(),
                                       Drag.None))
    spell.elapsed = 0
    spell.current_state = 1
    spell.state_changed = true

    spell.duration_states = {999, duration, 999, 999}

    spell.attack_func = function(self, other)
        local tile = self:get_current_tile()
        --TODO replace this with volcano effect (gotta make the animation)
        battle_helpers.spawn_visual_artifact(field,tile,impacts_texture,impacts_animation_path,"VOLCANO",0,0)
        if user.seconds_since_attack_landed then
            --update this value for ai logic if it exists
            user.seconds_since_attack_landed = 0
        end
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

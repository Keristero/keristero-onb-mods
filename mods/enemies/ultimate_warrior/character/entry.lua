
local enemy_info = {
    name = "RickAstley",
    hp = 100,
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

    --Set up character meta
    self:set_name(enemy_info.name)
    self:set_health(enemy_info.hp)
    self:set_texture(self.texture, true)
    self:set_height(30)
    self:share_tile(false)
    self:set_explosion_behavior(32, 1.0, false)
    self:set_position(0, 0)

    --Initial state
    self.animation:set_state("IDLE")
    self.animation:set_playback(Playback.Loop)
    self.ai_state = "spawning"
    self.ai_timer = 0
    self.ai_jumps = 0
    self.ai_target_jumps = math.random(2,3)
    self.frames_between_jumps = 10
    
    enraged = false

    self.update_func = function (self,dt)
        local character = self
        local character_facing = character:get_facing()
        if character:get_health() < 500 then
            enraged = true
        end
        --debug_print("original update_func called: "..character.ai_state)
        if character.ai_state == "idle" then
            character.ai_timer = character.ai_timer + 1
            if character.ai_timer > character.frames_between_jumps then
                local is_attacking = false
                character.ai_jumps = character.ai_jumps + 1
                if character.ai_jumps >= character.ai_target_jumps then
                    is_attacking = true
                    character.ai_state = "attacking"
                end
                big_brute_teleport(character,is_attacking)
                if is_attacking then
                    local action = action_random_attack(character)
                    character:card_action_event(action,ActionOrder.Voluntary)
                    action.action_end_func = function ()
                        character.ai_state = "idle"
                        character.ai_jumps = 0
                        self.ai_target_jumps = math.random(4,5)
                    end
                end
                character.ai_timer = 0
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


function big_brute_teleport(character,is_attacking)
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
            return not is_attacking
        end
        return true
    end)
    if #allowed_movement_tiles > 0 then
        target_tile = allowed_movement_tiles[math.random(#allowed_movement_tiles)]
    else
        target_tile = character:get_current_tile()
    end
    character:teleport(target_tile,ActionOrder.Immediate)
end

function action_random_attack(character)
    local attack_actions = {action_line_attack,action_hellfire}
    local chosen_one = attack_actions[math.random(#attack_actions)]
    return chosen_one(character)
end

function action_line_attack(character)
    local action_name = "line attack"
    debug_print('action '..action_name)

    local action = Battle.CardAction.new(character,"IDLE")
    action:set_lockout(make_sequence_lockout())

    action.execute_func = function(self)
        debug_print('executing action '..action_name)
        local step1 = Battle.Step.new()
        local step2 = Battle.Step.new()

        local actor = self:get_actor()
        action.attack_anim_started = false
        action.attack_time_counter = 0
        action.attack_time = 2
        if enraged then
            action.attack_time = 0.9
        end
        action.attack_anim_2_started = false
        action.attack_time_2_counter = 0
        action.attack_2_time = 2

        step1.update_func = function(self, dt)
            --debug_print('action '..action_name..' step 2')
            if not action.attack_anim_started then
                local anim = actor:get_animation()
                anim:set_state("ATTACK")
                anim:set_playback(Playback.Once)
                action.attack_anim_started = true
                local direction = actor:get_facing()
                local warning_duration = 0.5
                local fire_duration = 0.5
                local fire_damage = 200
                for i = 1, 9, 1 do
                    local t1 = actor:get_tile(direction,i)
                    if t1 then
                        fire_tower_spell(actor,fire_damage,fire_duration,warning_duration,t1:x(),t1:y())
                    end
                end
            end
            if action.attack_time_counter < action.attack_time then
                action.attack_time_counter = action.attack_time_counter + dt
            else
                debug_print('action '..action_name..' step 1 complete')
                local anim = actor:get_animation()
                anim:set_state("IDLE")
                anim:set_playback(Playback.Loop)
                self:complete_step()
            end
        end
        step2.update_func = function(self, dt)
            --debug_print('action '..action_name..' step 2')
            if not action.attack_anim_2_started then
                local anim = actor:get_animation()
                anim:set_state("ATTACK")
                anim:set_playback(Playback.Once)
                action.attack_anim_2_started = true
                local direction = actor:get_facing()
                local warning_duration = 0.5
                local fire_duration = 0.5
                local fire_damage = 200
                for i = 1, 9, 1 do
                    local t1 = actor:get_tile(direction,i)
                    if t1 then
                        fire_tower_spell(actor,fire_damage,fire_duration,warning_duration,t1:x(),t1:y()-1)
                        fire_tower_spell(actor,fire_damage,fire_duration,warning_duration,t1:x(),t1:y()+1)
                    end
                end
            end
            if action.attack_time_2_counter < action.attack_2_time then
                action.attack_time_2_counter = action.attack_time_2_counter + dt
            else
                debug_print('action '..action_name..' step 2 complete')
                local anim = actor:get_animation()
                anim:set_state("IDLE")
                anim:set_playback(Playback.Loop)
                self:complete_step()
            end
        end

        self:add_step(step1)
        if enraged then
            self:add_step(step2)
        end
    end
    return action
end

function action_hellfire(character)
    local action_name = "action_hellfire"
    debug_print('action '..action_name)

    local action = Battle.CardAction.new(character,"IDLE")
    action:set_lockout(make_sequence_lockout())

    action.execute_func = function(self)
        debug_print('executing action '..action_name)
        local step1 = Battle.Step.new()

        local actor = self:get_actor()
        action.attack_anim_started = false
        action.attack_time_counter = 0
        action.time_till_next_fire = 0
        action.waves = 3
        action.delay_between_waves = 1
        if enraged then
            action.waves = 5
            action.delay_between_waves = 0.8
        end
        action.attack_time = (action.waves*action.delay_between_waves)+1.5

        step1.update_func = function(self, dt)
            --debug_print('action '..action_name..' step 2')
            if action.time_till_next_fire <= 0 and action.waves > 0 then
                local anim = actor:get_animation()
                anim:set_state("ATTACK")
                anim:set_playback(Playback.Once)
                action.attack_anim_started = true
                local direction = actor:get_facing()
                local warning_duration = 1
                local fire_duration = 0.5
                local fire_damage = 200
                local current_tile_x = actor:get_current_tile():x()
                local field = actor:get_field()
                for x = 0, current_tile_x, 1 do
                    for y = 0, 4, 1 do
                        if math.random(1,3) == 3 then
                            local t1 = field:tile_at(x,y)
                            if t1 then
                                fire_tower_spell(actor,fire_damage,fire_duration,warning_duration,t1:x(),t1:y())
                            end
                        end
                    end
                end
                action.time_till_next_fire = action.delay_between_waves
                action.waves = action.waves - 1
            else
                action.time_till_next_fire = action.time_till_next_fire - dt
            end
            if action.attack_time_counter < action.attack_time then
                action.attack_time_counter = action.attack_time_counter + dt
            else
                debug_print('action '..action_name..' step 2 complete')
                local anim = actor:get_animation()
                anim:set_state("IDLE")
                anim:set_playback(Playback.Loop)
                self:complete_step()
            end
        end

        self:add_step(step1)
    end
    return action
end

function fire_tower_spell(user,damage,duration,warning_duration,x,y)
    local field = user:get_field()
    if x == 0 or x >= field:width()+1 or y == 0 or y >= field:height()+1 then
        return
    end
    local spell = Battle.Spell.new(user:get_team())
    spell:set_texture(fire_tower_texture, true)
    spell:highlight_tile(Highlight.Flash)
    spell:set_hit_props(
        make_hit_props(
            damage, 
            Hit.Impact | Hit.Flinch, 
            Element.Fire, 
            user:get_id(), 
            drag(Direction.Right, 0)
        )
    )
    spell.elapsed = 0
    spell.current_state = 1
    spell.state_changed = false

    spell.duration_states = {
        warning_duration,
        0.15,
        duration,
        0.15,
        999
    }

    spell.update_func = function(self,delta_time)
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
                anim:on_complete(function ()
                    print("anim finished!")
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
                anim:on_complete(function ()
                    print("anim finished! like totally")
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
            --if we are in damaging frames
            local current_tile = self:get_current_tile()
            current_tile:attack_entities(self)
        end
    end

    local anim = spell:get_animation()
    spell:sprite():hide()
    anim:load(fire_tower_animation_path)
    anim:set_state("START")

    field:spawn(spell, x, y)
    --use direct hit / back of field animation
end
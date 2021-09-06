
local enemy_info = {
    name = "BigBrute",
    hp = 120,
}

function debug_print(text)
    print("[bigbrute] "..text)
end

function package_init(self)
    debug_print("package_init called")
    --Required function, main package information

    --Load character resources
	self.texture = Engine.load_texture(_modpath.."battle.png")
	self.animation = self:get_animation()
	self.animation:load(_modpath.."battle.animation")

    --Set up character meta
    self:set_name(enemy_info.name)
    self:set_health(enemy_info.hp)
    self:set_texture(self.texture, true)
    self:set_height(30)
    self:share_tile(false)
    self:set_explosion_behavior(4, 1.0, false)
    self:set_position(0, 0)

    --Initial state
    self.animation:set_state("IDLE")
    self.animation:set_playback(Playback.Loop)
    self.ai_state = "spawning"
    self.ai_timer = 0
    self.ai_jumps = 0
    self.ai_target_jumps = math.random(4,5)
    self.frames_between_jumps = 40

    self.update_func = function (self,dt)
        local character = self
        local character_facing = character:get_facing()
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
                    local action = action_beast_breath(character)
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
    character:teleport(target_tile,ActionOrder.Immediate)
end

function action_beast_breath(character)
    local action_name = "beast breath"
    debug_print('action '..action_name)

    local action = Battle.CardAction.new(character,"IDLE")
    action:set_lockout(make_sequence_lockout())

    action.execute_func = function(self)
        debug_print('executing action '..action_name)
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
            --debug_print('action '..action_name..' step 1')
            if not action.pre_attack_anim_started then
                local anim = actor:get_animation()
                anim:set_state("PRE_ATTACK")
                anim:set_playback(Playback.Loop)
                action.pre_attack_anim_started = true
            end
            if action.pre_attack_time_counter < action.pre_attack_time then
                action.pre_attack_time_counter = action.pre_attack_time_counter + dt
            else
                self:complete_step()
            end
        end

        step2.update_func = function(self, dt)
            --debug_print('action '..action_name..' step 2')
            if not action.attack_anim_started then
                local anim = actor:get_animation()
                anim:set_state("ATTACK")
                anim:set_playback(Playback.Loop)
                action.attack_anim_started = true
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
        self:add_step(step2)
    end
    return action
end
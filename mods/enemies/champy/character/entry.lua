
local enemy_info = {
    name = "Champy",
    hp = 60,
}

local helpers = {
    timers={}
}
helpers.frames_to_seconds = function(frames)
    return 1000/(frames*16)
end
helpers.add_timer=function(callback,delay)
    debug_print("adding timer with delay of "..delay)
    helpers.timers[#helpers.timers+1] = {callback=callback,delay=delay}
end
helpers.update_timers=function(delta_time)
    for i, timer in pairs(helpers.timers) do
        if timer.delay > 0 then
            timer.delay = timer.delay - delta_time
        end
        if timer.delay <= 0 then
            timer.callback()
            helpers.timers[i] = nil
        end
    end
end

function debug_print(text)
    print("[mob] "..text)
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
    debug_print('set hp to: '..enemy_info.hp)

    --Initial state
    self.animation:set_state("IDLE")
    self.animation:set_playback(Playback.Loop)
    self.ai_state = "idle"

    helpers.add_timer(function ()
        ai_decide_move(self)
    end,1)

    self.update_func = function (self, delta_time)
        --debug_print("update_func called")
        helpers.update_timers(delta_time)
    end
    self.battle_start_func = function (self)
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

function ai_decide_move(character)
    debug_print("ai decide move from state "..character.ai_state)

    local targets = find_targets_ahead(character)
    if #targets > 0 then
        character:card_action_event(vanishing_teleport_action(character,2),ActionOrder.Voluntary)
    end

    helpers.add_timer(function ()ai_decide_move(character)end,1)
end

function find_targets_ahead(user)
    local field = user:get_field()
    local user_tile = user:get_current_tile()
    local user_team = user:get_team()
    local list = field:find_characters(function(character)
        return character:get_current_tile():y() == user_tile:y() and character:get_team() ~= user_team
    end)
    return list
end


function vanishing_teleport_action(player)
    print("vanishing teleport")

    local action = Battle.CardAction.new(player, "IDLE")
    action:set_lockout(make_sequence_lockout())

    action.execute_func = function(self, user)
        local step1 = Battle.Step.new()
        local step2 = Battle.Step.new()
        local step3 = Battle.Step.new()

        local ref = self
        local actor = ref:get_actor()

        step1.update_func = function(self, dt)
            self:complete_step()
        end

        step2.update_func = function(self, dt)
            self:complete_step()
        end

        step3.update_func = function(self, dt) 
        
        end

        self:add_step(step1)
        self:add_step(step2)
        self:add_step(step3)
    end
    return action
end
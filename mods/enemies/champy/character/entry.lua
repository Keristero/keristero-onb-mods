
local enemy_info = {
    name = "Champy",
    hp = 60,
}

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

    --Initial state
    self.animation:set_state("IDLE")
    self.animation:set_playback(Playback.Loop)
    self.ai_state = "spawning"
    self.ai_timer = 0

    self.update_func = function (self,dt)
        local character = self
        local character_facing = character:get_facing()
        debug_print("original update_func called: "..character.ai_state)
        if character.ai_state == "idle" then
            local enemy_tile = target_first_enemy_tile(character,character_facing,false)
            if enemy_tile == nil then
                debug_print('no target...')
                return
            end
            debug_print('aha, a target...')
            local reverse_dir = reverse_dir(character_facing)
            debug_print('reverse dir = '..reverse_dir)
            local target_tile = enemy_tile:get_tile(reverse_dir,1)
            local action = vanishing_teleport_action(character,target_tile)
            -- This callback has not actually been added yet
            action.action_end_func = function(self)
                debug_print('action end func')
                character.ai_state = "wait"
                character.ai_timer = 1.0
            end
            character:card_action_event(action,ActionOrder.Voluntary)
            character.ai_state = "vanishing"
        end

        if character.ai_state == "wait" then
            if character.ai_timer > 0 then
                character.ai_timer = character.ai_timer - dt
                debug_print('waiting...'..character.ai_timer)
                return
            end
            debug_print('finished waiting...'..character.ai_timer)
            character.ai_state = "idle"
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

function find_targets_ahead(user)
    local field = user:get_field()
    local user_tile = user:get_current_tile()
    local user_team = user:get_team()
    local list = field:find_characters(function(character)
        return character:get_current_tile():y() == user_tile:y() and character:get_team() ~= user_team
    end)
    return list
end

function target_first_enemy_tile(user,direction,can_hit_back_column)
    local field = user:get_field()
    local user_tile = user:get_current_tile()
    local targets = find_targets_ahead(user)
    if #targets == 0 then
        if can_hit_back_column then
            return field:tile_at(field:width(),user_tile:y())
        end
    elseif #targets == 1 then
        return targets[1]:get_current_tile()
    else
        local closest_x_dist = 10
        for index, character in ipairs(targets) do
            local x_dist = math.abs(character:get_current_tile():x()-user_tile:x())
            if x_dist < closest_x_dist then
                closest_x_dist = x_dist
            end
        end
        print('closest x dist '..closest_x_dist)
        return user:get_tile(direction,closest_x_dist)
    end
    return nil
end

function start_hide(character, target_tile, seconds, callback)
    local c = Battle.Component.new(character, Lifetimes.Battlestep)
    c.duration = seconds
    c.start_tile = character:get_current_tile()
    c.target_tile = target_tile
    debug_print("starting hide with duration "..c.duration..' start:'..c.start_tile:x()..','..c.start_tile:y()..' end:'..c.target_tile:x()..','..c.target_tile:y())


    c.update_func = function(self, dt)
        self.duration = self.duration - dt
        debug_print("updated hide component "..self.duration)
        if self.duration <= 0 then
            local id = self:get_owner():get_id()
            debug_print("adding entity "..id)
            self.target_tile:add_entity(self:get_owner())
            if callback then
                callback()
            end
            self:eject()
        end
    end

    c.scene_inject_func = function(self)
        local tile = self.start_tile
        local id = self:get_owner():get_id()
        tile:remove_entity_by_id(id)
        debug_print("removed entity "..id)
    end

    -- add to character
    character:register_component(c)
    return c
end


function vanishing_teleport_action(user,target_tile)
    print("vanishing teleport")

    local action = Battle.CardAction.new(user, "IDLE")
    action:set_lockout(make_sequence_lockout())

    action.execute_func = function(self)
        print('user'.. user:get_id().." attacking")
        local step1 = Battle.Step.new()
        local step2 = Battle.Step.new()
        local step3 = Battle.Step.new()
        local step4 = Battle.Step.new()

        local ref = self
        local actor = ref:get_actor()
        local field = actor:get_field()
        local start_tile = actor:get_current_tile()
        local done_teleport = false
        local done_punch = false
        local wait_before_return = 1.0
        local hide_component = nil

        --just testing
        --local particle_impact = Battle.ParticleImpact.new(ParticleType.Fire)
        --field:spawn(particle_impact,start_tile:x(),start_tile:y())

        step1.update_func = function(self, dt)
            if done_teleport then
                return
            end
            debug_print("vanishing teleport STEP 1")
            --reserve the start tile for when the champy returns
            local start_tile = user:get_current_tile()
            start_tile:reserve_entity_by_id(user:get_id())
            hide_component = start_hide(user,target_tile,0.448,function ()
                print("Finished hiding!")
                self:complete_step()
            end)
            done_teleport = true
        end

        step2.update_func = function(self, dt)
            if done_punch then
                return
            end
            debug_print("vanishing teleport STEP 2")

            debug_print("uppercut attack")
            local punch_anim = actor:get_animation()
            punch_anim:set_state("UPPER")
            punch_anim:set_playback(Playback.Once)
            punch_anim:on_frame(5, function ()
                local direction = user:get_facing()
                local target_tile = user:get_tile(direction,1)
                if target_tile then
                    fire_burst(user,target_tile,10)
                end
            end, true)
            punch_anim:on_complete(function()
                debug_print("completed uppercut attack")
                local idle_anim = actor:get_animation()
                idle_anim:set_state("IDLE")
                idle_anim:set_playback(Playback.Loop)
                self:complete_step()
            end)
            done_punch = true
        end

        step3.update_func = function(self, dt)
            if wait_before_return > 0 then
                debug_print("wait before return"..wait_before_return)
                wait_before_return = wait_before_return - dt
                return
            end
            self:complete_step()
        end

        step4.update_func = function(self, dt)
            debug_print("vanishing teleport STEP 4")
            local did_teleport = user:teleport(start_tile,ActionOrder.Involuntary)
            if did_teleport then
                self:complete_step()
            end
        end

        self:add_step(step1)
        self:add_step(step2)
        self:add_step(step3)
        self:add_step(step4)
    end
    return action
end

function fire_burst(user,target_tile,damage)
    debug_print("fireburst")
    local spell = Battle.Spell.new(user:get_team())
    
    --spell:set_texture(texture, true)
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

    spell.tic = 0
    spell.update_func = function(self)
        local current_tile = self:get_current_tile()
        --Deal damage on first tic
        if spell.tic == 0 then
            current_tile:attack_entities(self)
        else
            spell:delete()
        end
        spell.tic = spell.tic +1
    end

    spell.attack_func = function(self, other) 
        local current_tile = self:get_current_tile()
        --local hit_particle = Battle.ParticleImpact.new(ParticleType.Volcano)
        --user:get_field():spawn(hit_particle, current_tile:x(), current_tile:y())
    end

    user:get_field():spawn(spell, target_tile:x(), target_tile:y())
end

function teleport_effect_artifact(tile,is_appearing)

end
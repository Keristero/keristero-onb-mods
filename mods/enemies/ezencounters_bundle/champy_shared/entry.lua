local shared_folder_path = _modpath.."../champy_shared/"

local enemy_info = {
    name = "Champy"
}

local function debug_print(text)
    -- uncomment below to debug:
    -- print("[champy] "..text)
end

local punch_sfx = Engine.load_audio(shared_folder_path.."punch.ogg")
local punch2_sfx = Engine.load_audio(shared_folder_path.."punch2.ogg")


local function find_targets_ahead(user)
    local field = user:get_field()
    local user_tile = user:get_current_tile()
    local user_team = user:get_team()
    local list = field:find_characters(function(character)
        return character:get_current_tile():y() == user_tile:y() and character:get_team() ~= user_team
    end)
    return list
end

local function target_first_enemy_tile(user,direction,can_hit_back_column)
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

local function generic_artifact(texture_path, animation_path, state, field, tile)
    local fx = Battle.Artifact.new()
    fx:set_texture(Engine.load_texture(shared_folder_path..texture_path), true)
    fx:sprite():set_layer(-2)
    local anim = fx:get_animation()
    anim:load(shared_folder_path..animation_path)
    anim:set_state(state)
    anim:set_playback(Playback.Once)
    anim:on_complete(function ()
        fx:erase()
    end)
    anim:refresh(fx:sprite())

    field:spawn(fx, tile)

    return fx
end

local function teleport_effect_artifact(field, tile)
    return generic_artifact(
        "teleport_effect.png", 
        "teleport.animation", 
        "teleport_effect", 
        field, 
        tile
    )
end

local function punch_artifact(field, tile)
    return generic_artifact(
        "impacts.png", 
        "impacts.animation", 
        "volcano", 
        field, 
        tile
    )
end

local function fire_burst(user,target_tile,damage,is_2nd_punch)
    debug_print("fireburst")
    local spell = Battle.Spell.new(user:get_team())
    
    --spell:set_texture(texture, true)
    spell:highlight_tile(Highlight.Solid)
    spell:set_hit_props(
        HitProps.new(
            damage, 
            Hit.Impact | Hit.Flinch, 
            Element.Fire, 
            user:get_context(), 
            Drag.None
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
        local particle = punch_artifact(self:get_field(), current_tile)
        particle:set_offset(0, -(other:get_height()/2)-10)
    end

    user:get_field():spawn(spell, target_tile:x(), target_tile:y())

    if is_2nd_punch then
        Engine.play_audio(punch2_sfx, AudioPriority.High)
    else
        Engine.play_audio(punch_sfx, AudioPriority.High)
    end
end

local function start_hide(character, target_tile, seconds, callback)
    teleport_effect_artifact(character:get_field(), character:get_current_tile())
    local c = Battle.Component.new(character, Lifetimes.Battlestep)
    c.duration = seconds
    c.start_tile = character:get_current_tile()
    c.target_tile = target_tile
    print("starting hide with duration "..c.duration..' start:'..c.start_tile:x()..','..c.start_tile:y()..' end:'..c.target_tile:x()..','..c.target_tile:y())


    c.update_func = function(self, dt)
        if self:get_owner():get_health() == 0 then
            self:eject()
            return
        end

        self.duration = self.duration - dt
        debug_print("updated hide component "..self.duration)
        if self.duration <= 0 then
            local id = self:get_owner():get_id()
            debug_print("adding entity "..id)

            if callback then
                callback(self:get_owner(), self.target_tile)
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


local function vanishing_teleport_action(user,target_tile)
    print("vanishing teleport")
    target_tile:reserve_entity_by_id(user:get_id())

    local action = Battle.CardAction.new(user, "IDLE")
    action:set_lockout(make_sequence_lockout())

    action.execute_func = function(self)
        print('user'.. user:get_id().." attacking")
        local step1 = Battle.Step.new()
        local step2 = Battle.Step.new()
        local step3 = Battle.Step.new()
        local step4 = Battle.Step.new()
        local step5 = Battle.Step.new()

        local ref = self
        local actor = ref:get_actor()
        local field = actor:get_field()
        local start_tile = actor:get_current_tile()
        local done_teleport = false
        local done_punch = false
        local done_2nd_punch = false
        local wait_before_return = user._idle_steps_before_return
        local hide_component = nil

        local step1_done = false
        local step2_done = false
        local step3_done = false

        step1.update_func = function(self, dt)
            if step1_done then 
                self:complete_step()
            end

            if done_teleport then
                return
            end
            debug_print("vanishing teleport STEP 1")
            --reserve the start tile for when the champy returns
            local start_tile = user:get_current_tile()
            start_tile:reserve_entity_by_id(user:get_id())
            hide_component = start_hide(user,target_tile,0.448,
                function (owner, tile)
                    tile:add_entity(owner)
                    teleport_effect_artifact(owner:get_field(), tile)
                    print("Finished hiding!")
                    step1_done = true
                end
            )
            done_teleport = true
        end

        step2.update_func = function(self, dt)
            if step2_done then
                self:complete_step()
            end

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
                    fire_burst(user,target_tile,user._punch_damage)
                end
            end, true)
            punch_anim:on_complete(function()
                debug_print("completed uppercut attack")
                local idle_anim = actor:get_animation()
                idle_anim:set_state("IDLE")
                idle_anim:set_playback(Playback.Loop)

                if not user._punch_twice then 
                    idle_anim:on_complete(function()
                        wait_before_return = wait_before_return - 1
                    end, false)
                end

                step2_done = true
            end)
            done_punch = true
        end

        step3.update_func = function(self, dt)
            if step3_done then
                self:complete_step()
            end

            if done_2nd_punch then
                return
            end
            debug_print("jab attack")
            local punch_anim = actor:get_animation()
            punch_anim:set_state("JAB")
            punch_anim:set_playback(Playback.Once)
            punch_anim:on_frame(4, function ()
                local direction = user:get_facing()
                local target_tile = user:get_tile(direction,1)
                if target_tile then
                    fire_burst(user,target_tile,user._punch_damage,true)
                end
            end, true)
            punch_anim:on_complete(function()
                debug_print("completed jab attack")
                local idle_anim = actor:get_animation()
                idle_anim:set_state("IDLE")
                idle_anim:set_playback(Playback.Loop)

                if user._punch_twice then 
                    idle_anim:on_complete(function()
                        wait_before_return = wait_before_return - 1
                    end, false)
                end

                step3_done = true
            end)
            done_2nd_punch = true
        end

        step4.update_func = function(self, dt)
            if wait_before_return > 0 then
                debug_print("wait before return"..wait_before_return)
                return
            end
            self:complete_step()
        end

        step5.update_func = function(self, dt)
            debug_print("vanishing teleport STEP 5")
            teleport_effect_artifact(user:get_field(), user:get_current_tile())
            local did_teleport = user:teleport(start_tile,ActionOrder.Involuntary)
            if did_teleport then
                teleport_effect_artifact(user:get_field(), start_tile)
                self:complete_step()
            end
        end

        self:add_step(step1)
        self:add_step(step2)

        if user._punch_twice then 
            self:add_step(step3)
        end

        self:add_step(step4)
        self:add_step(step5)
    end
    return action
end

local function package_init(self)
    debug_print("package_init called")
    --Required function, main package information

    --Load character resources
	self.texture = Engine.load_texture(shared_folder_path.."battle.greyscaled.png")
	self.animation = self:get_animation()
	self.animation:load(shared_folder_path.."battle.animation")

    --Set up character meta
    self:set_name(enemy_info.name)
    self:set_texture(self.texture, true)
    self:set_height(30)
    self:share_tile(false)
    self:set_explosion_behavior(2, 1.0, false)
    self:set_offset(0, 0)
    --self:set_palette(Engine.load_texture(shared_folder_path.."battle.palette.png"))
    
    --Initial state
    self.animation:set_state("IDLE")
    self.animation:set_playback(Playback.Loop)
    self.ai_state = "spawning"
    self.ai_timer = 0
    self._punch_twice = false
    self._punch_damage = 20
    self._reveal_time = 60
    self._idle_steps_before_return = 2

    self.update_func = function (self,dt)
        local character = self
        local character_facing = character:get_facing()
        --debug_print("original update_func called: "..character.ai_state)
        if character.ai_state == "idle" then
            local enemy_tile = target_first_enemy_tile(character,character_facing,false)
            if enemy_tile == nil then
                --debug_print('no target...')
                return
            end

            if not enemy_tile:is_walkable() then 
                return 
            end

            debug_print('aha, a target...')
            local reverse_dir = Direction.reverse(character_facing)
            debug_print('reverse dir = '..reverse_dir)
            local target_tile = enemy_tile:get_tile(reverse_dir,1)
            local action = vanishing_teleport_action(character,target_tile)
            -- This callback has not actually been added yet
            action.action_end_func = function(self)
                debug_print('action end func')
                character.ai_state = "wait"
                character.ai_timer = character._reveal_time
            end
            character:card_action_event(action,ActionOrder.Voluntary)
            character.ai_state = "vanishing"
        end

        if character.ai_state == "wait" then
            if character.ai_timer > 0 then
                character.ai_timer = character.ai_timer - 1
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

return package_init
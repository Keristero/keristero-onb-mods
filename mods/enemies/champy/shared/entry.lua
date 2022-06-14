local battle_helpers = include("battle_helpers.lua")

local enemy_info = {
    name = "Champy"
}

local function debug_print(text)
    --print("[champy] "..text)
end

local punch_sfx = Engine.load_audio(_folderpath.."punch.ogg")
local punch2_sfx = Engine.load_audio(_folderpath.."punch2.ogg")
local teleport_effect_texture = Engine.load_texture(_folderpath.."teleport_effect.png")
local teleport_effect_animation_path = _folderpath.."teleport.animation"
local impacts_texture = Engine.load_texture(_folderpath.."impacts.png")
local impacts_animation_path = _folderpath.."impacts.animation"

function teleport_artifact(character,tile)
    local teleport_effect_artifact = battle_helpers.spawn_visual_artifact(character,tile,teleport_effect_texture,teleport_effect_animation_path,"TELEPORT_EFFECT",0,0)
    teleport_effect_artifact:sprite():set_layer(-2)
    return teleport_effect_artifact
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
        battle_helpers.spawn_visual_artifact(user,current_tile,impacts_texture,impacts_animation_path,"VOLCANO",0,-(other:get_height()/2)-10)
    end

    user:get_field():spawn(spell, target_tile:x(), target_tile:y())

    if is_2nd_punch then
        Engine.play_audio(punch2_sfx, AudioPriority.High)
    else
        Engine.play_audio(punch_sfx, AudioPriority.High)
    end
end

local function start_hide(character, target_tile, seconds, callback)
    teleport_artifact(character,character:get_current_tile())
    local c = Battle.Component.new(character, Lifetimes.Battlestep)
    c.duration = seconds
    c.target_reserved = false
    c.start_tile = character:get_current_tile()
    c.target_tile = target_tile
    c.update_func = function(self, dt)
        if self:get_owner():get_health() == 0 then
            self:eject()
            return
        end

        self.duration = self.duration - dt
        debug_print("updated hide component "..self.duration)
        if not c.target_reserved and self.duration <= seconds-0.240 then
            --a short delay after hiding (15 frames) try retargetting
            local facing = character:get_facing()
            local ignore_neutral_team = true
            local target = battle_helpers.get_first_target_ahead(character,ignore_neutral_team)
            if target ~= nil then
                local target_tile = target:get_current_tile()
                local reverse_dir = Direction.reverse(facing)
                c.target_tile = target_tile:get_tile(reverse_dir,1)
            end
            --now reserve the target tile
            c.target_tile:reserve_entity_by_id(character:get_id())
            c.target_reserved = true
        end
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
        local id = self:get_owner():get_id()
        self.start_tile:remove_entity_by_id(id)
        self.start_tile:reserve_entity_by_id(id)
        debug_print("removed entity "..id)
    end

    -- add to character
    character:register_component(c)
    return c
end


local function vanishing_teleport_action(user,target_tile)
    local action = Battle.CardAction.new(user, "IDLE")
    action:set_lockout(make_sequence_lockout())

    action.execute_func = function(self)
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
                    teleport_artifact(user,tile)
                    local obsts = tile:find_obstacles(function(o) return true end)

                    for i=1, #obsts do
                        obsts[i]:delete()
                    end
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
            actor:toggle_counter(true)
            punch_anim:on_frame(5, function ()
                local direction = user:get_facing()
                local target_tile = user:get_tile(direction,1)
                if target_tile then
                    fire_burst(user,target_tile,user._punch_damage)
                end
            end, true)
            punch_anim:on_frame(6, function ()
                actor:toggle_counter(false)
            end, true)
            punch_anim:on_complete(function()
                actor:toggle_counter(false)
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
            actor:toggle_counter(true)
            punch_anim:on_frame(4, function ()
                local direction = user:get_facing()
                local target_tile = user:get_tile(direction,1)
                if target_tile then
                    fire_burst(user,target_tile,user._punch_damage,true)
                end
            end, true)
            punch_anim:on_frame(5, function ()
                actor:toggle_counter(false)
            end, true)
            punch_anim:on_complete(function()
                actor:toggle_counter(false)
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
            teleport_artifact(user,user:get_current_tile())
            local did_teleport = user:teleport(start_tile,ActionOrder.Involuntary)
            if did_teleport then
                teleport_artifact(user,start_tile)
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

local function package_init(character)
    debug_print("package_init called")
    --Required function, main package information

    --Load character resources
	character.texture = Engine.load_texture(_folderpath.."battle.greyscaled.png")
	character.animation = character:get_animation()
	character.animation:load(_folderpath.."battle.animation")

    --Set up character meta
    character:set_name(enemy_info.name)
    character:set_texture(character.texture, true)
    character:set_height(30)
    character:share_tile(false)
    character:set_explosion_behavior(2, 1.0, false)
    character:set_offset(0, 0)
    character:set_element(Element.Fire)

    --defense rules
    character.defense = Battle.DefenseVirusBody.new()
    character:add_defense_rule(character.defense)
    
    --Initial state
    character.animation:set_state("IDLE")
    character.animation:set_playback(Playback.Loop)
    character.ai_state = "spawning"
    character.ai_timer = 0
    character._punch_twice = false
    character._punch_damage = 20
    character._reveal_time = 60
    character._idle_steps_before_return = 2

    character.update_func = function (self,dt)
        local character = self
        local character_facing = character:get_facing()
        --debug_print("original update_func called: "..character.ai_state)
        if character.ai_state == "idle" then
            local ignore_neutral_team = true
            local target = battle_helpers.get_first_target_ahead(character,ignore_neutral_team)
            if target == nil then
                return
            end
            local enemy_tile = target:get_current_tile()
            debug_print('aha, a target...')
            local reverse_dir = Direction.reverse(character_facing)
            debug_print('reverse dir = '..reverse_dir)
            local target_tile = enemy_tile:get_tile(reverse_dir,1)
            if not target_tile:is_walkable() then
                return
            end
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
    character.battle_start_func = function (self)
        self.ai_state = "idle"
        debug_print("battle_start_func called")
    end
    character.battle_end_func = function (self)
        debug_print("battle_end_func called")
    end
    character.on_spawn_func = function (self, spawn_tile) 
        debug_print("on_spawn_func called")
   end
    character.can_move_to_func = function (tile)
        debug_print("can_move_to_func called")
        return battle_helpers.is_tile_free_for_movement(tile,character,true)
    end
    character.delete_func = function (self)
        debug_print("delete_func called")
    end
end

return package_init
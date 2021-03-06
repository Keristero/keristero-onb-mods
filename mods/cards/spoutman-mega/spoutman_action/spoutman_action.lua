local battle_helpers = include("battle_helpers.lua")

local spoutman_texture = Engine.load_texture(_folderpath .. "spoutman_spaced.png")
local spoutman_animation_path = _folderpath .. "spoutman_spaced.animation"
local hose_texture = Engine.load_texture(_folderpath .. "spoutman-hose.png")
local hose_animation_path = _folderpath .. "spoutman-hose.animation"

local hydro_pump = include("hydro_pump/hydro_pump.lua")
local bubbler = include("bubbler/bubbler.lua")
local do_nothing = function (self,dt) end

local spoutman = {
    name="SpoutMan",
    description="Watr atck!\nBhnd 2row\npower-up",
    codes={"*"},
    damage=50,
    time_freeze=true,
    hits=3,
    can_boost=true,
    element=Element.Aqua,
    card_class=CardClass.Mega
}

spoutman.card_create_action = function(user, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(user, "PLAYER_IDLE")

    action:set_lockout(make_sequence_lockout())

    action.execute_func = function(self, user)
        print("in custom card action execute_func()!")

        local steps = {}
        for i = 1, 6, 1 do
            steps[#steps+1] = Battle.Step.new()
        end

        local actor = self:get_actor()
        local field = actor:get_field()
        local current_tile = actor:get_current_tile()
        local facing = user:get_facing()

        local spoutman_pre_attack_frames = 32
        local should_use_hose = false
        local should_use_bubbler = false
        local spoutman_hydro_pump_warmup_frames = 60
        --hose frames = 4,4,4,4

        --bubbler warm up frames (20)
        --bubbler firing frame 1 (4)

        steps[1].update_func = function(self, dt)
            --hide the player and spawn a spoutman artifact
            actor:hide()
            action.spoutman_artifact = Battle.Artifact.new()
            action.spoutman_artifact:set_texture(spoutman_texture, true)
            action.spoutman_artifact:set_facing(facing)
            local anim = action.spoutman_artifact:get_animation()
            field:spawn(action.spoutman_artifact,current_tile:x(),current_tile:y())
            anim:load(spoutman_animation_path)
            anim:set_state("APPEAR")
            anim:refresh(action.spoutman_artifact:sprite())
            anim:on_complete(function()
                self:complete_step()
            end)
            steps[1].update_func = do_nothing
        end

        steps[2].update_func = function(self, dt)
            --start idle animation
            action.spoutman_idle_time = spoutman_pre_attack_frames
            local anim = action.spoutman_artifact:get_animation()
            anim:set_state("IDLE")

            steps[2].update_func = function (self,dt) 
                --wait until idle time is up
                if action.spoutman_idle_time > 0 then
                    action.spoutman_idle_time = action.spoutman_idle_time - 1
                    return
                end
                self:complete_step()
            end
        end

        steps[3].update_func = function(self, dt)
            --decide if spoutman should use bubbler or hose
            local field = actor:get_field()
            local actor_tile = actor:get_current_tile()
            if facing == Direction.Right and actor_tile:x() <= 2 then
                --if player is in back two tiles (facing right)
                should_use_hose = true
            elseif facing == Direction.Left and actor_tile:x() >= field:width()-1 then
                --if player is in back two tiles (facing left)
                should_use_hose = true
            else
                --if player is anywhere else
                should_use_bubbler = true
            end
            self:complete_step()
        end

        steps[4].update_func = function(self, dt)
            --use bubbler, otherwise skip
            if not should_use_bubbler then
                self:complete_step()
                return
            end
            local anim = action.spoutman_artifact:get_animation()
            anim:set_state("BUBBLER")
            anim:on_complete(function()
                self:complete_step()
            end)
            local frames_before_shot = 20
            steps[4].update_func = function (self,dt)
                frames_before_shot = frames_before_shot - 1
                if frames_before_shot == 0 then
                    bubbler.create_aqua_shot(actor, actor:get_context(),props.damage)
                end
            end
        end

        steps[5].update_func = function(self, dt)
            --use hose, otherwise skip
            if not should_use_hose then
                self:complete_step()
                return
            end
            local anim = action.spoutman_artifact:get_animation()
            anim:set_state("GRAB_HOSE")
            anim:on_complete(function()
                anim:set_state("HOSE")
                anim:set_playback(Playback.Loop)
            end)
            local use_hydro_pump = function (self,dt)
                if spoutman_hydro_pump_warmup_frames > 0 then
                    spoutman_hydro_pump_warmup_frames = spoutman_hydro_pump_warmup_frames -1
                    return
                end
                --find enemies ahead of user (any row)
                local target = battle_helpers.get_first_target_ahead(user,false,true,true,false)

                --if there is an enemy ahead of the user, get the first one
                local distance = 0
                --if there is a nearby character, hit that
                if target then
                    distance = math.abs(current_tile:x()-target:get_current_tile():x())
                else
                    --if there is no neaby character, hit end of field
                    if facing == Direction.Right then
                        distance = math.abs(current_tile:x()-field:width())
                    else
                        distance = current_tile:x()-1
                    end
                end
                --if there is an obstacle straight ahead, hit that instead
                local blocking_obstacle = battle_helpers.get_first_target_ahead(user,false,false,false,true)
                if blocking_obstacle then
                    obstacle_distance = math.abs(current_tile:x()-blocking_obstacle:get_current_tile():x())
                    distance = math.min(obstacle_distance,distance)
                end

                --create the torrent
                local torrent = hydro_pump.create_torrent(actor,props.damage, distance)
                field:spawn(torrent,current_tile:x(),current_tile:y())

                --Wiggle spoutman while hose is blasting
                local frames_till_wiggle = 4
                local wiggle_offset = -2
                steps[5].update_func = function ()
                    --spoutman wiggles while firing the hydro pump
                    if not torrent:is_deleted() then
                        frames_till_wiggle = frames_till_wiggle -1
                        if frames_till_wiggle == 0 then
                            action.spoutman_artifact:set_offset(wiggle_offset,0)
                            frames_till_wiggle = 4
                            if wiggle_offset == -2 then
                                wiggle_offset = 0
                            else
                                wiggle_offset = -2
                            end
                        end
                    else
                        action.spoutman_artifact:set_offset(0,0)
                    end
                end
            end
            steps[5].update_func = function(self, dt)
                action.hose_artifact = Battle.Artifact.new()
                action.hose_artifact:set_texture(hose_texture, true)
                local hose_anim = action.hose_artifact:get_animation()
                field:spawn(action.hose_artifact,current_tile:x(),current_tile:y())
                hose_anim:load(hose_animation_path)
                hose_anim:set_state("DEFAULT")
                hose_anim:refresh(action.hose_artifact:sprite())
                hose_anim:on_complete(function ()
                    action.hose_artifact:erase()
                    self:complete_step()
                end)
                steps[5].update_func = use_hydro_pump
            end
        end

        steps[6].update_func = function(self, dt)
            --leave
            local anim = action.spoutman_artifact:get_animation()
            anim:set_state("LEAVE")
            anim:on_complete(function()
                action.spoutman_artifact:erase()
                self:complete_step()
            end)
            steps[6].update_func = do_nothing
        end

        for index, step in ipairs(steps) do
            self:add_step(step)
        end
    end

    return action
end

return spoutman
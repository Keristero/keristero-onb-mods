local cloud_texture = Engine.load_texture(_folderpath .. "cloud.png")
local cloud_animation_path = _folderpath.. "cloud.animation"
local thunder = include('/thunder/thunder.lua')

local function spawn_cloud(character)
    local visual_artifact = Battle.Artifact.new()
    --visual_artifact:hide()
    visual_artifact:set_texture(cloud_texture,true)
    local anim = visual_artifact:get_animation()
    local sprite = visual_artifact:sprite()
    local field = character:get_field()
    local facing = character:get_facing()
    local tile = character:get_current_tile()
    anim:load(cloud_animation_path)
    anim:set_state("IDLE")
    anim:set_playback(Playback.Loop)
    sprite:set_layer(1)
    visual_artifact:set_facing(facing)
    anim:refresh(sprite)
    field:spawn(visual_artifact, tile:x(), tile:y())
    visual_artifact.thunder_frames = 0
    visual_artifact.update_func = function ()
        print('updating cloud!')
        if anim:get_state() == "THUNDER" then
            if visual_artifact.thunder_frames > 0 then
                visual_artifact.thunder_frames = visual_artifact.thunder_frames - 1
            else
                anim:set_state("IDLE")
            end
        end
    end
    visual_artifact.can_move_to_func = function ()
        return true 
    end
    visual_artifact:set_shadow(Shadow.Small)
    visual_artifact:show_shadow(true)
    return visual_artifact
end

local function add_component(character)
    local c = Battle.Component.new(character, Lifetimes.Battlestep)
    c.float_tic = 0
    c.base_elevation = 25

    c.update_func = function(self, dt)
        local player = self:get_owner()

        if self:get_owner():get_health() == 0 then
            c:cleanup_func()
            self:eject()
            return
        end

        c.float_tic = c.float_tic + 0.1
        if c.float_tic >= math.pi*2 then
            c.float_tic = 0
        end

        local new_elevation = c.base_elevation+(math.sin(c.float_tic)*5)
        player:set_elevation(new_elevation)

        if c.cloud_artifact then
            c.cloud_artifact:set_elevation(new_elevation)
            local player_tile = player:get_current_tile()
            local cloud_tile = c.cloud_artifact:get_current_tile()
            if cloud_tile:x() ~= player_tile:x() or cloud_tile:y() ~= player_tile:y() then
                c.cloud_artifact:teleport(player_tile,ActionOrder.Immediate)
            end
        end
    end

    c.cleanup_func = function (self)
        if c.cloud_artifact then
            c.cloud_artifact:delete()
        end
    end

    c.scene_inject_func = function(self)
        local player = self:get_owner()
        local tile = player:get_current_tile()
        player:set_air_shoe(true)
        player:set_float_shoe(true)
        player:register_status_callback(Hit.Stun,function ()
            print('CLOUD DETECTED STUN')
            local anim = c.cloud_artifact:get_animation()
            anim:set_state("THUNDER")
            anim:set_playback(Playback.Loop)
            c.cloud_artifact.thunder_frames = 30
            thunder.create_spell(player)
        end)
        c.cloud_artifact = spawn_cloud(player)
        c.cloud_artifact:set_elevation(c.base_elevation)
        player:set_elevation(c.base_elevation)
    end

    -- add to character
    character:register_component(c)
    return c
end

return add_component
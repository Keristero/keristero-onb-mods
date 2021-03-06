local battle_helpers = include("battle_helpers.lua")

local attachment_texture = Engine.load_texture(_folderpath .. "attachment.png")
local attachment_animation_path = _folderpath .. "attachment.animation"
local vulcan_impact_texture = Engine.load_texture(_folderpath .. "vulcan_impact.png")
local vulcan_impact_animation_path = _folderpath .. "vulcan_impact.animation"
local bullet_hit_texture = Engine.load_texture(_folderpath .. "bullet_hit.png")
local bullet_hit_animation_path = _folderpath .. "bullet_hit.animation"
local gun_sfx = Engine.load_audio(_folderpath .. "gun.ogg")

local vulcan = {
    name="Vulcan1",
    description="3-shot to pierce 1 panel!",
    codes={"B","D","*","S"},
    damage=10,
    time_freeze=false,
    shots_animated=4,
    hits=3,
    can_boost=true,
    card_class=CardClass.Standard
}

vulcan.card_create_action = function(user,props)
    local action = Battle.CardAction.new(user, "PLAYER_SHOOTING")
	action:set_lockout(make_animation_lockout())
    action.shots_animated = vulcan.shots_animated
    action.hits = vulcan.hits
    local vulcan_direction = user:get_facing()
    local f_padding = {1,0.032}
    action.frames = {f_padding,f_padding,f_padding,f_padding,f_padding,f_padding,f_padding}
    local hit_props = HitProps.new(
        props.damage, 
        Hit.Impact | Hit.Flinch, 
        Element.None,
        user:get_context(),
        Drag.None
    )

    action.before_exec = function (action)
        local f_flash = {2,0.032}
        local f_between = {3,0.048}
        for i = 1, action.shots_animated, 1 do
            table.insert(action.frames,3,f_between)
            table.insert(action.frames,3,f_flash)
        end
        local FRAME_DATA = make_frame_data(action.frames)
        action:override_animation_frames(FRAME_DATA)
    end

    --prepare override frame data
    action.before_exec(action)

    action.execute_func = function(self, user)
        --local props = self:copy_metadata()
        local attachment = self:add_attachment("BUSTER")
        local attachment_sprite = attachment:sprite()
        attachment_sprite:set_texture(attachment_texture)
        attachment_sprite:set_layer(-2)

        local attachment_animation = attachment:get_animation()
        attachment_animation:load(attachment_animation_path)
        attachment_animation:set_state("SPAWN")
        
        user:toggle_counter(true)

        self:add_anim_action(2,function()
            attachment_animation:set_state("ATTACK")
            attachment_animation:set_playback(Playback.Loop)
		end)

        for i = 1, action.hits, 1 do
            self:add_anim_action(i*4,function()
                Engine.play_audio(gun_sfx, AudioPriority.Highest)
                local target = battle_helpers.get_first_target_ahead(user)
                if not target then
                --ignore any hits beyond the first one
                return
                end
                local hit_tile = target:get_current_tile()
                create_vulcan_damage(user,vulcan_direction,hit_tile,hit_props)
                battle_helpers.spawn_visual_artifact(user,hit_tile,vulcan_impact_texture,vulcan_impact_animation_path,"IDLE",-10,-55)
                battle_helpers.spawn_visual_artifact(user,hit_tile,bullet_hit_texture,bullet_hit_animation_path,"HIT",math.random(-20,20),math.random(-55,-30))
            end)
        end

        self:add_anim_action(5,function ()
            user:toggle_counter(false)
        end)

        self:add_anim_action(#action.frames-5,function()
            --show lag animation for last 5 overriden frames
            attachment_animation:set_state("END")
        end)

    end
    action.action_end_func = function ()
        user:toggle_counter(false)
    end
    return action
end

function create_vulcan_damage(user,direction,tile,hit_props)
    local hit_tiles = {tile}
    if not hit_tiles[1]:is_edge() then
        hit_tiles[2] = hit_tiles[1]:get_tile(direction,1)
    end
    for index, tile in ipairs(hit_tiles) do
        local spell = Battle.Spell.new(user:get_team())
        spell:set_hit_props(hit_props)
        spell.update_func = function(self, dt)
            local current_tile = self:get_current_tile()
            current_tile:attack_entities(self)
            self:delete()
        end
        user:get_field():spawn(spell, tile)
    end
end

return vulcan
local battle_helpers = include("battle_helpers.lua")
local blade_texture = Engine.load_texture(_folderpath .. "/blades/trans_sword_3.png")
local blade_animation = _folderpath .. "/blades/trans_sword_2.animation"

local sword = {
    name="sword",
    description="template for sword attacks",
    codes={"S"},
    element=Element.sword,
    damage=80,
    time_freeze=false,
    can_boost=true,
    card_class=CardClass.Standard,
    attack_pattern = {
        {0,2},
        {1,2,2,2,2,2},
        {0,2}
    },
    apply_scale_effect = function(node,original_width,original_height,progress)
        local width = original_width
        local height = original_height
        node:set_width(width)
        node:set_height(height)
    end,
    apply_color_effect = function(node,progress)
        local r = 0
        local g = math.floor(255-(256*progress))
        local b = math.floor(128+(256*progress))
        local a = math.floor(255-progress*255)
        local color = Color.new( r, g, b, a ) 
        node:set_color(color)
    end
}
--BN6 specific sword notes
--  Normal Swing
--  ONB animation name:PLAYER_SWORD
--8f Starting lag
--2f (arm forward)
--2f (arm diagonal forward)
--2f (arm diagonal behind)
-- Normal sword swings damage on the same frame after the hilt appears

--  Overhead Swing
--  ONB animation name:PLAYER_CHOP
--1f Starting lag
--3f (arm up)
--2f (arm forward)
--2f (arm diagonal behind)

--Notes on Blades
--Six frames in total, 
--each duration is 2f
--last frame duration is 4f
local function create_new_blade_section(parent,texture,animation_path,state)
    --create node
    local node = parent:create_node()
    node:set_texture(texture)

    --setup animation
    local anim = Engine.Animation.new(animation_path)
    anim:load(animation_path)
    --set animation frame
    anim:set_state(state)
    anim:refresh(node)
    return {node=node,animation=anim,w=node:get_width(),h=node:get_height()}
end

local relative_positions_to_attack = battle_helpers.get_tile_relative_positions_from_pattern(sword.attack_pattern,false)

sword.card_create_action = function(user,props)
    local user_sprite = user:sprite()
    local user_animation = user:get_animation()
    local action = Battle.CardAction.new(user, "PLAYER_SWORD")
	action:set_lockout(make_animation_lockout())
    local blade_sections = {}
    local max_blade_sections = 7 --Maximum blade sections to spawn, should be one for each frame of the sword swing
    local blade_animation_frames = 10 --How many frames it takes to finish color/scale effects on blade trails
    local has_attacked = false

    --override sword swing animation frames
    action.frames = {{1,0.032},{2,0.032},{3,0.032},{4,0.032},{5,0.032},{6,0.128}}
    local FRAME_DATA = make_frame_data(action.frames)
    action:override_animation_frames(FRAME_DATA)

    action:add_anim_action(2,function ()
        --Create hilt attachment
        local hilt = action:add_attachment("HILT")
        local hilt_sprite = hilt:sprite()
        hilt_sprite:set_texture(user:get_texture())
        hilt_sprite:set_layer(-2)
        hilt_sprite:enable_parent_shader(true)
        local hilt_anim = hilt:get_animation()
        hilt_anim:copy_from(user:get_animation())
        hilt_anim:set_state("HILT")

        --Stores hilt endpoint position every second frame, for every other position we blend with this value
        --the end effect is interpolated frames for a smooter sword appearance regardless of the navi used.
        local last_end_point_relative = nil
        local tic = 0

        --create the spell that does the damage
        local spell = Battle.Spell.new(user:get_team())
        spell:set_facing(user:get_facing())
        spell:set_hit_props(
            HitProps.new(
                sword.damage,
                Hit.Impact | Hit.Flinch | Hit.Flash,
                sword.element,
                user:get_context(),
                Drag.None
            )
        )
        user:get_field():spawn(spell, user:get_current_tile())

        action.action_end_func = function ()
            while #blade_sections >= 1 do
                blade_section = blade_sections[1]
                user_sprite:remove_node(blade_section.node)
                table.remove( blade_sections, 1 )
            end   
        end

        action.update_func = function ()
            tic = tic + 1
            --Animate blade sections
            for index, blade_section in ipairs(blade_sections) do
                --Dont animate the final blade section, or the the final sword blade frame will fade
                if index ~= max_blade_sections then
                    local progress = math.max(0,math.min(1,(tic-index)/blade_animation_frames))
                    sword.apply_color_effect(blade_section.node,progress)
                    sword.apply_scale_effect(blade_section.node,blade_section.w,blade_section.h,progress)
                end
            end
            if tic > 1 then
                --attack (if we have not already)
                if not has_attacked then
                    local tiles_to_attack = battle_helpers.get_tiles_at_relative_positions(spell:get_field(),spell:get_current_tile(),relative_positions_to_attack)
                    battle_helpers.attack_tiles(spell,tiles_to_attack)
                    has_attacked = true
                else
                    if spell then
                        spell:erase()
                        spell = nil
                    end
                end
                --Create new blade sections per update, until we reach a maximum
                if #blade_sections < max_blade_sections then
                    --create a new blade_section
                    local target_state = ''..#blade_sections+1
                    local blade_section = create_new_blade_section(user,blade_texture,blade_animation,target_state)
                    table.insert(blade_sections, blade_section)
                    --set initial color
                    sword.apply_color_effect(blade_section.node,0)
                    sword.apply_scale_effect(blade_section.node,blade_section.w,blade_section.h,0)
                    --find endpoint relative to user origin
                    local points = {{user_animation,"ORIGIN","HILT"},{hilt_anim,"ORIGIN","ENDPOINT"}}
                    local end_point_relative = battle_helpers.sum_relative_positions_between_animation_points(points)
                    if #blade_sections % 2 == 0 and last_end_point_relative then
                        end_point_relative.x = math.floor(end_point_relative.x+last_end_point_relative.x)/2
                        end_point_relative.y = math.floor(end_point_relative.y+last_end_point_relative.y)/2
                        last_end_point_relative = end_point_relative
                    else
                        last_end_point_relative = end_point_relative
                    end

                    --finally we can set the position of the blade relative to the player's origin
                    blade_section.node:set_offset(end_point_relative.x,end_point_relative.y)
                end
            end
        end
    end)

    return action
end

return sword
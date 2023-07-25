--sword revamp V1.1
local battle_helpers = include("battle_helpers.lua")
local blade_texture = Engine.load_texture(_folderpath .. "/assets/blade.png")
local blade_animation = _folderpath .. "/assets/blade.animation"
local cut_texture = Engine.load_texture(_folderpath .. "/assets/cut.png")
local cut_animation = _folderpath .. "/assets/cut.animation"
local hit_particle_texture = Engine.load_texture(_folderpath .. "/assets/hit_particles.png")
local hit_particle_animation = _folderpath .. "/assets/hit_particles.animation"

local sword_attack_positions = {
    on_player = 0,
    on_closest_enemy = 1,
    on_first_target_ahead = 2,
    furthest_tile = 3,
    player_front = 4
}

local sword = {
    name="Sword",
    description="template for sword attacks",
    codes={"S","W","D"},
    element=Element.sword,
    damage=80,
    hitflags=Hit.Impact | Hit.Flinch | Hit.Flash,
    drag=Drag.None,
    time_freeze=false,
    can_boost=true,
    card_class=CardClass.Standard,
    attack_distance=1,--number of tiles ahead to center (player_front) attack patterns
    attack_pattern_center=sword_attack_positions.player_front,
    --Possible values:
    --(on_player) the center of the pattern is on the player
    --(player_front) the center of the pattern is x tiles ahead of the player, x is sword.attack_distance
    --(on_closest_enemy) the center of the pattern is on the closest enemy
    --(on_first_ahead) the center of the pattern is on the first target in user's row
    --(furthest_tile) furthest on screen tile in the same row
    fallback_attack_pattern_center=sword_attack_positions.player_front,
    --Possible values: (same as attack_pattern_center, but only used if no target was found initially)
    attack_pattern = {
        {1},
    },
    attack_center_tile=true,
    highlight_tiles=true,
    cut_animation_state = "STANDARD",
    hit_particle_animation_state = "SMALL_GREEN",
    cut_afterimages = {},--{{lifetime_ms,velocity_x,velocity_y},...}
    sfx = Engine.load_audio(_folderpath.."sfx.ogg"),
    apply_scale_effect = function(node,original_width,original_height,progress)
        local width = original_width
        local height = original_height
        node:set_width(width)
        node:set_height(height)
    end,
    apply_color_effect = function(node,progress)
        local r = 0
        local g = math.floor(220-progress*150)
        local b = math.floor(200-progress*40)
        local a = math.floor(255-progress*255)
        local color = Color.new( r, g, b, a )
        node:set_color(color)
    end
}

local function create_new_blade_section(parent,texture,animation_path,state)
    --create node
    local node = parent:create_node()
    node:set_texture(texture)
    node:set_layer(-2)

    --setup animation
    local anim = Engine.Animation.new(animation_path)
    anim:load(animation_path)
    --set animation frame
    anim:set_state(state)
    anim:refresh(node)
    return {node=node,animation=anim,w=node:get_width(),h=node:get_height()}
end

local function find_target_tile(user,targeting_mode)
    --find the target tile
    local target = nil
    local spell_center_tile = nil
    --primary targetting option
    if targeting_mode == sword_attack_positions.on_player then
        spell_center_tile = user:get_current_tile()
    end
    if targeting_mode == sword_attack_positions.in_front_of_player then
        spell_center_tile = user:get_current_tile()
    end
    if targeting_mode == sword_attack_positions.on_closest_enemy then
        target = battle_helpers.get_first_target_ahead(user,false,true,true,false)
    end
    if targeting_mode == sword_attack_positions.on_first_target_ahead then
        target = battle_helpers.get_first_target_ahead(user,false,false,false,false)
    end
    if targeting_mode == sword_attack_positions.furthest_tile then
        local x = 6
        if user:get_facing() == Direction.Left then
            x = 1
        end
        local y = user:get_current_tile():y()
        spell_center_tile = user:get_field():tile_at(x,y)
    end
    if targeting_mode == sword_attack_positions.player_front then
        spell_center_tile = user:get_tile(user:get_facing(),1)
    end
    if target then
        spell_center_tile = target:get_current_tile()
    end
    return spell_center_tile
end

local relative_positions_to_attack = battle_helpers.get_tile_relative_positions_from_pattern(sword.attack_pattern,sword.attack_center_tile)

sword.card_create_action = function(user,props)
    local user_sprite = user:sprite()
    local user_animation = user:get_animation()
    local action = Battle.CardAction.new(user, "PLAYER_SWORD")
	action:set_lockout(make_animation_lockout())
    local blade_sections = {}
    local max_blade_sections = 7 --Maximum blade sections to spawn, should be one for each frame of the sword swing
    local blade_animation_frames = 10 --How many frames it takes to finish color/scale effects on blade trails
    local has_attacked = false
    local highlight_tiles_func = nil

    --override sword swing animation frames
    action.frames = {{1,0.032},{2,0.032},{3,0.032},{4,0.032},{5,0.032},{6,0.128}}
    local FRAME_DATA = make_frame_data(action.frames)
    action:override_animation_frames(FRAME_DATA)

    action:add_anim_action(2,function ()
        --Create hilt attachment
        local field = user:get_field()
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
        --primary targeting
        local spell_center_tile = nil
        spell_center_tile = find_target_tile(user,sword.attack_pattern_center)
        --fallback targetting option
        if not spell_center_tile then
            spell_center_tile = find_target_tile(user,sword.fallback_attack_pattern_center)
        end
        if not spell_center_tile then
            --If we dont have a center tile for the sword, we should never attack
        end
        local spell = Battle.Spell.new(user:get_team())
        spell:set_facing(user:get_facing())
        spell:set_hit_props(
            HitProps.new(
                sword.damage,
                sword.hitflags,
                sword.element,
                user:get_context(),
                sword.drag
            )
        )
        spell.attack_func = function (self,other)
            --Spawn hit particle on impact
            local y_offset = (other:get_height() or 40)*-0.5
            battle_helpers.spawn_visual_artifact(user,other:get_current_tile(),hit_particle_texture,hit_particle_animation,sword.hit_particle_animation_state,0,y_offset,false)
        end
        field:spawn(spell, spell_center_tile)

        --Highlight the tiles we are going to attack to give a fair 1 frame warning, so nice
        if sword.highlight_tiles then
            local tiles_to_highlight = battle_helpers.get_tiles_at_relative_positions(field,spell_center_tile,relative_positions_to_attack)
            highlight_tiles_func = battle_helpers.highlight_tiles_update_func(tiles_to_highlight,8,battle_helpers.highlight_style.fast_wave)
        end

        local cut_fx = battle_helpers.spawn_visual_artifact(user,spell_center_tile,cut_texture,cut_animation,sword.cut_animation_state,spell_center_tile:x(),spell_center_tile:y(),false)
        cut_fx.update_func = function (self)
            sword.apply_color_effect(cut_fx,0.2)
            if not self.done_first_update then
                for i, afterimage_data in ipairs(sword.cut_afterimages) do
                    battle_helpers.drop_trace_fx(cut_fx,afterimage_data[1],afterimage_data[2],afterimage_data[3])
                end
                self.done_first_update = true
            end
        end

        action.action_end_func = function ()
            while #blade_sections >= 1 do
                blade_section = blade_sections[1]
                user_sprite:remove_node(blade_section.node)
                table.remove( blade_sections, 1 )
            end   
        end

        action.update_func = function ()
            tic = tic + 1
            --Highlight tiles
            if highlight_tiles_func then
                highlight_tiles_func()
            end
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
                    local tiles_to_attack = battle_helpers.get_tiles_at_relative_positions(field,spell:get_current_tile(),relative_positions_to_attack)
                    battle_helpers.attack_tiles(spell,tiles_to_attack)
                    has_attacked = true
                    Engine.play_audio(sword.sfx, AudioPriority.Low)
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
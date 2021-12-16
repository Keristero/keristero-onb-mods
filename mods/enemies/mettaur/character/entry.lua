local MobTracker = include("mob_tracker.lua")
local left_mob_tracker = MobTracker:new()
local right_mob_tracker = MobTracker:new()
local character_info = {name = "Mettaur", hp = 40,height=20,damage = 10}

local wave_texture = Engine.load_texture(_modpath .. "shockwave.png")
local wave_sfx = Engine.load_audio(_modpath .. "shockwave.ogg")
local teleport_animation_path = _modpath .. "teleport.animation"
local teleport_texture_path = _modpath .. "teleport.png"
local teleport_texture = Engine.load_texture(teleport_texture_path)

local debug = true
local function debug_print(text)
    if debug then
        print("[mettaur] " .. text)
    end
end

function get_tracker_from_direction(facing)
    if facing == Direction.Left then
        return left_mob_tracker
    elseif facing == Direction.Right then
        return right_mob_tracker
    end
end

function advance_a_turn_by_facing(facing)
    local mob_tracker = get_tracker_from_direction(facing)
    return mob_tracker:advance_a_turn()
end

function get_active_mob_id_for_same_direction(facing)
    local mob_tracker = get_tracker_from_direction(facing)
    return mob_tracker:get_active_mob()
end

function add_enemy_to_tracking(enemy)
    local facing = enemy:get_facing()
    local id = enemy:get_id()
    local mob_tracker = get_tracker_from_direction(facing)
    mob_tracker:add_by_id(id)
end

function remove_enemy_from_tracking(enemy)
    local facing = enemy:get_facing()
    local id = enemy:get_id()
    local mob_tracker = get_tracker_from_direction(facing)
    mob_tracker:remove_by_id(id)
end

function package_init(self)
    debug_print("package_init called")
    -- Required function, main package information

    -- Load character resources
    self.texture = Engine.load_texture(_modpath .. "battle.greyscaled.png")
    self.animation = self:get_animation()
    self.animation:load(_modpath .. "battle.animation")

    -- Load extra resources

    -- Set up character meta
    self:set_name(character_info.name)
    self:set_health(character_info.hp)
    self:set_texture(self.texture, true)
    self:set_height(character_info.height)
    self:share_tile(false)
    self:set_explosion_behavior(4, 1, false)
    self:set_offset(0, 0)
    self:set_palette(Engine.load_texture(_modpath.."battle_v3.palette.png"))

    --defense rules
    self.defense = Battle.DefenseVirusBody.new()
    print("defense was created")
    self:add_defense_rule(self.defense)

    -- Initial state
    self.animation:set_state("IDLE")
    self.animation:set_playback(Playback.Loop)
    self.frames_between_actions = 40 
    self.cascade_frame_index = 5 --lower = faster shockwaves
    self.ai_wait = self.frames_between_actions
    self.ai_taken_turn = false

    self.update_func = function(self, dt)
        local facing = self:get_facing()
        local field = self:get_field()
        local id = self:get_id()
        local active_mob_id = get_active_mob_id_for_same_direction(facing)
        if active_mob_id == id then
            take_turn(self)
        end
    end

    self.battle_start_func = function(self)
        debug_print("battle_start_func called")
        local field = self:get_field()
        local mob_sort_func = function(a,b)
            local met_a_tile = field:get_entity(a):get_current_tile()
            local met_b_tile = field:get_entity(b):get_current_tile()
            local var_a = (met_a_tile:x()*3)+met_a_tile:y()
            local var_b = (met_b_tile:x()*3)+met_b_tile:y()
            return var_a < var_b
        end
        left_mob_tracker:sort_turn_order(mob_sort_func)
        right_mob_tracker:sort_turn_order(mob_sort_func,true)--reverse sort direction
    end
    self.battle_end_func = function(self)
        debug_print("battle_end_func called")
        left_mob_tracker:clear()
        right_mob_tracker:clear()
    end
    self.on_spawn_func = function(self, spawn_tile)
        debug_print("on_spawn_func called")
        add_enemy_to_tracking(self)
    end
    self.can_move_to_func = function(tile)
        debug_print("can_move_to_func called")
        return is_tile_free_for_movement(tile,self)
    end
    self.delete_func = function(self) 
        debug_print("delete_func called")
        remove_enemy_from_tracking(self)
    end
end

function find_target(self)
    local field = self:get_field()
    local team = self:get_team()
    local target_list = field:find_characters(function(other_character)
        return other_character:get_team() ~= team
    end)
    if #target_list == 0 then
        debug_print("No targets found!")
        return
    end
    local target_character = target_list[1]
    return target_character
end

function take_turn(self)
    local id = self:get_id()
    if self.ai_wait > 0 or self.ai_taken_turn then
        self.ai_wait = self.ai_wait - 1
        return
    end
    self.ai_taken_turn = true
    local moved = move_towards_character(self)
    if moved then
        self.ai_wait = self.frames_between_actions
        self.ai_taken_turn = false
        return
    end
    local shockwave_action = action_shockwave(self)
    local next_action = shockwave_action
    next_action.action_end_func = function()
        local facing = self:get_facing()
        self.ai_wait = self.frames_between_actions
        self.ai_taken_turn = false
        advance_a_turn_by_facing(facing)
    end
    self:card_action_event(next_action, ActionOrder.Voluntary)

end

function move_towards_character(self)
    local target_character = find_target(self)
    local target_character_tile = target_character:get_current_tile()
    local tile = self:get_current_tile()
    local moved = false
    local target_movement_tile = nil
    if tile:y() < target_character_tile:y() then
        target_movement_tile = tile:get_tile(Direction.Down,1)
    end
    if tile:y() > target_character_tile:y() then
        target_movement_tile = tile:get_tile(Direction.Up,1)
    end
    if target_movement_tile then
        moved = self:teleport(target_movement_tile, ActionOrder.Immediate)
        if moved then
            spawn_visual_artifact(tile,self,teleport_texture,teleport_animation_path,"SMALL_TELEPORT_FROM",0,0)
        end
    end
    return moved
end

function action_shockwave(character)
    local action_name = "shockwave"
    local facing = character:get_facing()
    debug_print('action ' .. action_name)

    local action = Battle.CardAction.new(character, "ATTACK")
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
        self:add_anim_action(6,function ()
            character:toggle_counter(true)
        end)
		self:add_anim_action(12,function()
            local tile = character:get_tile(facing,1)
            spawn_shockwave(character, tile, facing, character_info.damage, wave_texture, wave_sfx, character.cascade_frame_index)
        end)
        self:add_anim_action(13,function ()
            character:toggle_counter(false)
        end)
	end
    return action
end

function is_tile_free_for_movement(tile,character)
    --Basic check to see if a tile is suitable for a chracter of a team to move to
    if tile:get_team() ~= character:get_team() then return false end
    if not tile:is_walkable() then return false end
    local occupants = tile:find_characters(function(other_character)
        return true
    end)
    if #occupants > 0 then 
        return false
    end
    return true
end

function spawn_visual_artifact(tile,character,texture,animation_path,animation_state,position_x,position_y)
    local field = character:get_field()
    local visual_artifact = Battle.Artifact.new()
    visual_artifact:set_texture(texture,true)
    local anim = visual_artifact:get_animation()
    anim:load(animation_path)
    anim:set_state(animation_state)
    anim:on_complete(function()
        visual_artifact:delete()
    end)
    visual_artifact:sprite():set_offset(position_x,position_y)
    field:spawn(visual_artifact, tile:x(), tile:y())
end

function spawn_shockwave(owner, tile, direction, damage, wave_texture, wave_sfx, cascade_frame_index)
    local owner_id = owner:get_id()
    local team = owner:get_team()
    local field = owner:get_field()
    local cascade_frame = cascade_frame_index
    local spawn_next
    spawn_next = function()
        if not tile:is_walkable() then return end

        Engine.play_audio(wave_sfx, AudioPriority.Highest)

        local spell = Battle.Spell.new(team)
        spell:set_facing(direction)
        spell:highlight_tile(Highlight.Solid)
        spell:set_hit_props(HitProps.new(damage, Hit.Flash, Element.None, owner_id, Drag.new()))

        local sprite = spell:sprite()
        sprite:set_texture(wave_texture)
        sprite:set_layer(-1)

        local animation = spell:get_animation()
        animation:load(_modpath .. "shockwave.animation")
        animation:set_state("DEFAULT")

        animation:on_frame(cascade_frame, function()
            tile = tile:get_tile(direction, 1)
            spawn_next()
        end, true)
        animation:on_complete(function() spell:erase() end)

        spell.update_func = function()
            spell:get_current_tile():attack_entities(spell)
        end

        field:spawn(spell, tile)
    end

    spawn_next()
end

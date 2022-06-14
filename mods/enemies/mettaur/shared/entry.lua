local MobTracker = include("mob_tracker.lua")
local battle_helpers = include("battle_helpers.lua")
local left_mob_tracker = MobTracker:new()
local right_mob_tracker = MobTracker:new()

local wave_texture = Engine.load_texture(_folderpath .. "shockwave.png")
local wave_sfx = Engine.load_audio(_folderpath .. "shockwave.ogg")
local teleport_animation_path = _folderpath .. "teleport.animation"
local teleport_texture_path = _folderpath .. "teleport.png"
local teleport_texture = Engine.load_texture(teleport_texture_path)
local guard_hit_effect_texture = Engine.load_texture(_folderpath .. "guard_hit.png")
local guard_hit_effect_animation_path = _folderpath .. "guard_hit.animation"
local tink_sfx = Engine.load_audio(_folderpath .. "tink.ogg")

local function debug_print(text)
    --print("[mettaur] " .. text)
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

function package_init(self,character_info)
    debug_print("package_init called")
    -- Required function, main package information

    -- Load character resources
    self.texture = Engine.load_texture(_folderpath .. "battle.greyscaled.png")
    self.animation = self:get_animation()
    self.animation:load(_folderpath .. "battle.animation")

    -- Load extra resources

    -- Set up character meta
    self:set_name(character_info.name)
    self:set_health(character_info.hp)
    self:set_texture(self.texture, true)
    self:set_height(character_info.height)
    self:share_tile(false)
    self:set_explosion_behavior(2, 1, false)
    self:set_offset(0, 0)
    self:set_palette(Engine.load_texture(character_info.palette))

    --defense rules
    self.defense = Battle.DefenseVirusBody.new()
    self:add_defense_rule(self.defense)

    -- Initial state
    self.animation:set_state("IDLE")
    self.animation:set_playback(Playback.Loop)
    self.frames_between_actions = character_info.move_delay
    self.cascade_frame_index = character_info.cascade_frame --lower = faster shockwaves
    self.shockwave_animation = character_info.shockwave_animation
    self.shockwave_damage = character_info.damage
    self.can_guard = character_info.can_guard
    self.replacement_panel = character_info.replacement_panel
    self.ai_wait = self.frames_between_actions
    self.ai_taken_turn = false

    self.update_func = function(self, dt)
        local facing = self:get_facing()
        local field = self:get_field()
        local id = self:get_id()
        local active_mob_id = get_active_mob_id_for_same_direction(facing)
        if active_mob_id == id then
            take_turn(self)
        else
            idle_action(self)
        end
    end

    self.battle_start_func = function(self)
        debug_print("battle_start_func called")
        add_enemy_to_tracking(self)
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
        --In theory we should not need to do this as they would be cleared at the end of the last battle
        --However there is a bug in ONB V2 which causes battle_end_func to be missed sometimes.
        left_mob_tracker:clear()
        right_mob_tracker:clear()
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

function idle_action(self)
    if self.can_guard then
        --if the mettaur can guard, queue up a guard for after the current action
        if self.guarding_defense_rule then
            local anim = self:get_animation()
            anim:set_state("GUARD_PERSIST")
        elseif not self.guard_transition then
            begin_guard(self)
        end
    end
end

function end_guard(character)
    character.guard_transition = true
    local anim = character:get_animation()
    anim:set_state("GUARD_END")
    anim:set_playback(Playback.Once)
    character:remove_defense_rule(character.guarding_defense_rule)
    character.guarding_defense_rule = nil
    anim:on_complete(function()
        character.guard_transition = false
	end)
end

function begin_guard(character)
    character.guard_transition = true
    local anim = character:get_animation()
    anim:set_state("GUARD_START")
    anim:set_playback(Playback.Once)
    
    anim:on_complete(function()
        character.guard_transition = false
        character.guarding_defense_rule = Battle.DefenseRule.new(0,DefenseOrder.Always)
        character.guarding_defense_rule.can_block_func = function(judge, attacker, defender)
            local attacker_hit_props = attacker:copy_hit_props()
            if attacker_hit_props.flags & Hit.Breaking == Hit.Breaking then
                --cant block breaking hits with guard
                return
            end
            judge:block_impact()
            judge:block_damage()
            if attacker_hit_props.damage > 0 then
                Engine.play_audio(tink_sfx, AudioPriority.Highest)
                battle_helpers.spawn_visual_artifact(character,character:get_current_tile(),guard_hit_effect_texture,guard_hit_effect_animation_path,"DEFAULT",0,-30)
            end
        end
        character:add_defense_rule(character.guarding_defense_rule)
	end)
end

function take_turn(self)
    local id = self:get_id()
    if self.ai_wait > 0 or self.ai_taken_turn then
        self.ai_wait = self.ai_wait - 1
        if not self.guarding_defense_rule and not self.guard_transition and not self.shockwave_action then
            local anim = self:get_animation()
            anim:set_state("IDLE")
        end
        return
    end
    self.ai_taken_turn = true
    
    if self.guarding_defense_rule and not self.guard_transition then
        self.ai_wait = self.frames_between_actions
        self.ai_taken_turn = false
        end_guard(self)
        return
    end

    local moved = move_towards_character(self)
    if moved then
        self.ai_wait = self.frames_between_actions
        self.ai_taken_turn = false
        return
    end
    self.shockwave_action = action_shockwave(self)
    self.shockwave_action.action_end_func = function()
        local facing = self:get_facing()
        self.ai_wait = self.frames_between_actions
        self.ai_taken_turn = false
        self.shockwave_action = nil
        advance_a_turn_by_facing(facing)
    end
    self:card_action_event(self.shockwave_action, ActionOrder.Voluntary)
end

function move_towards_character(self)
    local target_character = find_target(self)
    local target_character_tile = target_character:get_current_tile()
    local tile = self:get_current_tile()
    local field = self:get_field()
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
            battle_helpers.spawn_visual_artifact(self,tile,teleport_texture,teleport_animation_path,"SMALL_TELEPORT_FROM",0,0)
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
            spawn_shockwave(character, tile, facing, character.shockwave_damage, wave_texture,character.shockwave_animation, wave_sfx, character.cascade_frame_index,character.replacement_panel)
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

function spawn_shockwave(owner, tile, direction, damage, wave_texture,wave_animation, wave_sfx, cascade_frame_index,new_tile_state)
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
        animation:load(_folderpath .. wave_animation)
        animation:set_state("DEFAULT")
        animation:refresh(sprite)

        animation:on_frame(cascade_frame, function()
            tile = tile:get_tile(direction, 1)
            spawn_next()
        end, true)
        animation:on_complete(function() spell:erase() end)

        spell.update_func = function()
            spell:get_current_tile():attack_entities(spell)
            if new_tile_state then
                spell:get_current_tile():set_state(new_tile_state)
            end
        end

        field:spawn(spell, tile)
    end

    spawn_next()
end


return package_init
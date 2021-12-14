local character_info = {name = "Mettaur", hp = 40,height=20}
local debug = true
local function debug_print(text)
    if debug then
        print("[mettaur] " .. text)
    end
end

local enemy_tracker = {
    left={},
    right={},
    next_turns={},
    previous_turns={},
    current_left=nil,
    current_right=nil,
    next_turn_mappings_created=false
}

local function direction_to_string(direction)
    if Direction.Left == direction then
        return "left"
    elseif Direction.Right == direction then
        return "right"
    end
    return nil
end

function add_enemy_to_tracking(enemy)
    local enemy_facing = enemy:get_facing()
    if Direction.Left == enemy_facing then
        enemy_tracker.left[#enemy_tracker.left+1] = enemy:get_id()
    elseif Direction.Right == enemy_facing then
        enemy_tracker.right[#enemy_tracker.right+1] = enemy:get_id()
    end
end

function sort_met_id_array(field,array,sort_left)
    table.sort(array,function(a,b)
        local met_a_tile = field:get_entity(a):get_current_tile()
        local met_b_tile = field:get_entity(b):get_current_tile()
        return met_a_tile:x() < met_b_tile:x() == sort_left
    end)
end

function package_init(self)
    debug_print("package_init called")
    -- Required function, main package information

    -- Load character resources
    self.texture = Engine.load_texture(_modpath .. "battle.png")
    self.animation = self:get_animation()
    self.animation:load(_modpath .. "battle.animation")

    -- Load extra resources

    -- Set up character meta
    self:set_name(character_info.name)
    self:set_health(character_info.hp)
    self:set_texture(self.texture, true)
    self:set_height(character_info.height)
    self:share_tile(false)
    self:set_explosion_behavior(4, 1.0, false)
    self:set_offset(0, 0)

    --defense rules
    self.defense = Battle.DefenseVirusBody.new()
    print("defense was created")
    self:add_defense_rule(self.defense)

    -- Initial state
    self.animation:set_state("IDLE")
    self.animation:set_playback(Playback.Loop)

    self.update_func = function(self, dt)
        local facing = self:get_facing()
        local field = self:get_field()
    end

    self.battle_start_func = function(self)
        debug_print("battle_start_func called")
    end
    self.battle_end_func = function(self)
        debug_print("battle_end_func called")
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
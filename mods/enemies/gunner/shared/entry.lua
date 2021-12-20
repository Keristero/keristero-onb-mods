local shared_folder_path = _modpath.."../shared/"

local enemy_info = {
    name = "Gunner"
}

local function debug_print(text)
    print("[Gunner] "..text)
end

local scanning_click_sfx = Engine.load_audio(shared_folder_path.."scanning_click.ogg")

local function find_targets_ahead(user)
    local field = user:get_field()
    local user_tile = user:get_current_tile()
    local user_team = user:get_team()
    local list = field:find_characters(function(character)
        return character:get_current_tile():y() == user_tile:y() and character:get_team() ~= user_team
    end)
    return list
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
    self.ai_state = "idle"

    self.update_func = function (self,dt)
        local character = self
        local character_facing = character:get_facing()
        if self.ai_state == "idle" then
            
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
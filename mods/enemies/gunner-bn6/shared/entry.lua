local battle_helpers = include("battle_helpers.lua")

local enemy_info = {
    name = "Gunner"
}

local function debug_print(text)
    print("[Gunner] "..text)
end

local scanning_click_sfx = Engine.load_audio(_folderpath.."scanning_click_norm.ogg")
local gun_sfx = Engine.load_audio(_folderpath.."gun.ogg")
local scanning_lock_sfx = Engine.load_audio(_folderpath.."scanning_lock_norm.ogg")
local reticle_texture = Engine.load_texture(_folderpath .. "reticle.png")
local reticle_animation_path = _folderpath .. "reticle.animation"
local ground_bullet_texture = Engine.load_texture(_folderpath .. "ground_bullet.png")
local ground_bullet_animation_path = _folderpath .. "ground_bullet.animation"

function spell_delayed_bullet(character,target_tile,damage)
    local facing = character:get_facing()
    local team = character:get_team()
    local spell = Battle.Spell.new(team)
    local anim = spell:get_animation()
    local sprite = spell:sprite()
    spell:set_texture(ground_bullet_texture,true)
    anim:load(ground_bullet_animation_path)
    anim:set_state("DEFAULT")
    anim:refresh(sprite)
    anim:set_playback(Playback.Once)
    spell.frames_before_impact = 10
    spell.warning_frames = 3
    spell:set_hit_props(HitProps.new(
        10,
        Hit.Flash,
        Element.None,
        character:get_context(),
        Drag.None)
    )
    anim:on_complete(function()
        spell:delete()
    end)
    spell.update_func = function (self)
        local tile = spell:get_current_tile()
        if self.warning_frames > 0 then
            tile:highlight(Highlight.Solid)
            self.warning_frames = self.warning_frames - 1
        end
        if self.frames_before_impact > 0 then
            self.frames_before_impact = self.frames_before_impact -1
        else
            tile:attack_entities(self)
        end
    end
    spell.can_move_to_func = function ()
        return true
    end
    return spell
end

local function sweep_should_switch_direction(next_tile,team)
    return (next_tile:is_edge() or next_tile:get_team() == team)
end

function spell_reticle(character,scan_finished_callback,reticle_travel_frames,sweep)
    local team = character:get_team()
    local spell = Battle.Spell.new(team)
    local anim = spell:get_animation()
    local sprite = spell:sprite()
    spell:set_texture(reticle_texture,true)
    anim:load(reticle_animation_path)
    anim:set_state("RETICLE_MOVE")
    anim:refresh(sprite)
    anim:set_playback(Playback.Loop)
    spell:set_offset(0,-20)
    sprite:set_layer(-4)
    spell.move_direction = character:get_facing()
    spell.update_func = function (self)
        local current_animation_state = anim:get_state()
        if current_animation_state == "RETICLE_MOVE" then
            local current_tile = spell:get_current_tile()
            if current_tile:is_edge() then
                scan_finished_callback(current_tile,false)
                spell:delete()
                return
            end
            local next_tile = spell:get_tile(spell.move_direction,1)
            if not spell:is_sliding() then
                local targets = current_tile:find_characters(function (enemy)
                    return enemy:get_team() ~= team
                end)
                if #targets > 0 then
                    anim:set_state("RETICLE_LOCK")              
                    Engine.play_audio(scanning_lock_sfx, AudioPriority.Highest)
                    anim:on_complete(function()
                        spell:delete()
                        pcall(function ()
                            scan_finished_callback(current_tile,true)
                        end)
                    end)
                else
                    if not sweep then
                        --just slide like normal
                        spell:slide(next_tile,frames(reticle_travel_frames),frames(0),ActionOrder.Voluntary)
                        return
                    end
                    local reticle_should_switch_direction = sweep_should_switch_direction(next_tile,team)
                    if reticle_should_switch_direction then
                        spell.move_direction = Direction.reverse(spell.move_direction)
                    else
                        spell:slide(next_tile,frames(reticle_travel_frames),frames(0),ActionOrder.Voluntary)
                    end
                end
            end
        end
    end
    spell.can_move_to_func = function ()
        return true
    end
    return spell
end

function action_fire(character,target_tile,shots,shots_animated)
    local action = Battle.CardAction.new(character,"FIRING")
    local field = character:get_field()
    local team = character:get_team()
    local sweeping = character.sweeping_reticle
	action:set_lockout(make_animation_lockout())

    local f_idle = {1,0.016}
    local f_flash_left = {2,0.016}
    local f_left_fade_1 = {3,0.016}
    local f_left_fade_2 = {4,0.032}
    local f_left_fade_3 = {5,0.016}
    local f_flash_right = {6,0.016}
    local f_right_fade_1 = {7,0.016}
    local f_right_fade_2 = {8,0.032}
    local f_right_fade_3 = {9,0.016}
    action.frames = {}
    local animate_left = true
    for i = 1, shots_animated, 1 do
        if animate_left then
            table.insert(action.frames,f_flash_left)
            table.insert(action.frames,f_left_fade_1)
            table.insert(action.frames,f_left_fade_2)
            table.insert(action.frames,f_left_fade_3)
            animate_left = false
        else
            table.insert(action.frames,f_flash_right)
            table.insert(action.frames,f_right_fade_1)
            table.insert(action.frames,f_right_fade_2)
            table.insert(action.frames,f_right_fade_3)
            animate_left = true
        end
    end
    local FRAME_DATA = make_frame_data(action.frames)
    action:override_animation_frames(FRAME_DATA)

    local function gun_shooty_pew()
        local scanned_tile = target_tile
        local sweep_direction = character:get_facing()
        if sweeping then
            for i = 0, action.bullets_fired, 1 do
                local next_tile_distance = math.min(1,action.bullets_fired)
                scanned_tile = scanned_tile:get_tile(sweep_direction,next_tile_distance)
                if sweep_should_switch_direction(scanned_tile,team) then
                    sweep_direction = Direction.reverse(sweep_direction)
                    scanned_tile = scanned_tile:get_tile(sweep_direction,next_tile_distance)
                end
            end
        end
        local spell_bullet = spell_delayed_bullet(character,scanned_tile,character.bullet_damage)
        field:spawn(spell_bullet, scanned_tile:x(), scanned_tile:y())
        Engine.play_audio(gun_sfx, AudioPriority.Highest)
        action.bullets_fired = action.bullets_fired + 1
    end
    action.execute_func = function (self,user)
        action.bullets_fired = 0
        user:toggle_counter(true)
        self:add_anim_action(1,function()
            gun_shooty_pew()
        end)
        self:add_anim_action(10,function()
            user:toggle_counter(false)
        end)
        for i = 1, shots, 1 do
            self:add_anim_action(1+(i*8),function()
                gun_shooty_pew()
            end)
        end
    end
    return action
end

function action_scan(character)
    local field = character:get_field()
    local team = character:get_team()
    local facing = character:get_facing()
    local reticle_spawn_tile = character:get_current_tile()

    Engine.play_audio(scanning_click_sfx, AudioPriority.Highest)

    local action = Battle.CardAction.new(character, "SCANNING")
	action:set_lockout(make_animation_lockout())
    action.update_func = function (self)

    end
    action.execute_func = function(self, user)
        self:add_anim_action(4,function ()
            if self.reticle_spell then
                return
            end
            local scan_finished_callback = function (tile,target_was_found)
                if target_was_found then
                    character.ai_state = "firing"
                    character.animation:set_state("PRE_FIRING")
                    character.attack_action = action_fire(character,tile,character.shots,character.shots+3)
                    character.attack_action.action_end_func = function ()
                        character.ai_state = "cooldown"
                        character.cooldown = 30
                    end
                    character:card_action_event(character.attack_action, ActionOrder.Immediate)
                else
                    character.ai_state = "cooldown"
                    character.cooldown = 30
                end
                if self then
                    self:end_action()
                end
            end
            self.reticle_spell = spell_reticle(character,scan_finished_callback,character.reticle_travel_frames,character.sweeping_reticle)
            self.reticle_spell.on_delete = function ()
                self.reticle_spell = nil
            end
            if character.sweeping_reticle then
                --for reticles that sweep back and forth, find first tile of another team's to spawn the reticle on
                while reticle_spawn_tile:get_team() == team do
                    reticle_spawn_tile = reticle_spawn_tile:get_tile(facing,1)
                end
            end
            field:spawn(self.reticle_spell, reticle_spawn_tile:x(), reticle_spawn_tile:y())
        end)
	end
    return action
end


local function package_init(self)
    --Required function, main package information

    --Load character resources
	self.texture = Engine.load_texture(_folderpath.."battle.greyscaled.png")
	self.animation = self:get_animation()
	self.animation:load(_folderpath.."battle.animation")

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
    self.bullet_damage = 10
    self.ai_state = "idle"
    self.cooldown = 30
    self.reticle_travel_frames = 13
    self.sweeping_reticle = false
    self.shots = 3
    local character = self

    local scanning_interrupt = function ()
        if character.current_scan_action then
            character.current_scan_action:end_action()
        end
        self.ai_state = "idle"
        self.animation:set_state("IDLE")
    end
    self:register_status_callback(Hit.Stun,scanning_interrupt)
    self:register_status_callback(Hit.Drag,scanning_interrupt)

    self.update_func = function (character,dt)
        if self.ai_state == "cooldown" then
            if self.cooldown > 0 then
                self.cooldown = self.cooldown - 1
                return
            end
            self.ai_state = "idle"
            self.animation:set_state("IDLE")
        elseif self.ai_state == "idle" then
            local targets = battle_helpers.find_targets_ahead(character)
            local filtered_targets = {}
            for index, entity in ipairs(targets) do
                if entity:get_team() ~= Team.Other then
                    filtered_targets[#filtered_targets+1] = entity
                end
            end
            if #filtered_targets > 0 then
                local action = action_scan(character)
                action.action_end_func = function ()
                    if action.reticle_spell then
                        action.reticle_spell:delete()
                    end
                    character.current_scan_action = nil
                end
                character.current_scan_action = action
                self.ai_state = "scanning"
                character:card_action_event(action, ActionOrder.Voluntary)
            end
        end
    end
    self.battle_start_func = function (self)
    end
    self.battle_end_func = function (self)
    end
    self.on_spawn_func = function (self, spawn_tile) 
   end
    self.delete_func = function (self)
        scanning_interrupt()
    end
end

return package_init
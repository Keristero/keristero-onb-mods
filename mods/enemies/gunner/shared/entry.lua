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
    print('created bullet')
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

function spell_reticle(character,scan_finished_callback)
    print('created reticle')
    local facing = character:get_facing()
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
    spell.update_func = function (self)
        local current_animation_state = anim:get_state()
        if current_animation_state == "RETICLE_MOVE" then
            local current_tile = spell:get_current_tile()
            if current_tile:is_edge() then
                print('reticle went off edge')
                scan_finished_callback(current_tile,false)
                spell:delete()
                return
            end
            local next_tile = spell:get_tile(facing,1)
            if not spell:is_sliding() then
                local targets = current_tile:find_characters(function (enemy)
                    return enemy:get_team() ~= team
                end)
                if #targets > 0 then
                    anim:set_state("RETICLE_LOCK")              
                    Engine.play_audio(scanning_lock_sfx, AudioPriority.Highest)
                    anim:on_complete(function()
                        scan_finished_callback(current_tile,true)
                        spell:delete()
                    end)
                else
                    spell:slide(next_tile,frames(13),frames(0),ActionOrder.Voluntary)
                end
            end
        end
    end
    spell.can_move_to_func = function ()
        return true
    end
    return spell
end

function action_fire(character,target_tile)
    local action = Battle.CardAction.new(character, "FIRING")
    local field = character:get_field()
	action:set_lockout(make_animation_lockout())
    local function gun_shooty_pew()
        local spell_bullet = spell_delayed_bullet(character,target_tile,character.bullet_damage)
        field:spawn(spell_bullet, target_tile:x(), target_tile:y())
        Engine.play_audio(gun_sfx, AudioPriority.Highest)
    end
    action.execute_func = function (self,user)
        self:add_anim_action(2,function ()
            user:toggle_counter(true)
            gun_shooty_pew()
        end)
        self:add_anim_action(11,function ()
            user:toggle_counter(false)
            gun_shooty_pew()
        end)
        self:add_anim_action(20,gun_shooty_pew)
    end
    action.update_func = function (self)
    end
    return action
end

function action_scan(character)
    print('creating scan action')
    local field = character:get_field()
    local facing = character:get_facing()
    local current_tile = character:get_current_tile()

    Engine.play_audio(scanning_click_sfx, AudioPriority.Highest)

    local action = Battle.CardAction.new(character, "SCANNING")
	action:set_lockout(make_animation_lockout())
    action.update_func = function (self)

    end
    action.execute_func = function(self, user)
        self:add_anim_action(4,function ()
            if action.reticle_spell then
                return
            end
            local scan_finished_callback = function (tile,target_was_found)
                if target_was_found then
                    character.ai_state = "firing"
                    character.animation:set_state("PRE_FIRING")
                    character.attack_action = action_fire(user,tile)
                    character.attack_action.action_end_func = function ()
                        character.ai_state = "cooldown"
                        character.cooldown = 30
                    end
                    character:card_action_event(character.attack_action, ActionOrder.Immediate)
                else
                    character.ai_state = "cooldown"
                    character.cooldown = 30
                end
                self:end_action()
            end
            action.reticle_spell = spell_reticle(character,scan_finished_callback)
            action.reticle_spell.on_delete = function ()
                action.reticle_spell = nil
            end
            field:spawn(action.reticle_spell, current_tile:x(), current_tile:y())
        end)
	end
    action.action_end_func = function ()
        print('action done mate')
        if action.reticle_spell then
            action.reticle_spell:delete()
        end
    end
    return action
end


local function package_init(self)
    debug_print("package_init called")
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
    local character = self

    local scanning_interrupt = function ()
        print('interrupting scan')
        if character.current_scan_action then
            if character.current_scan_action.reticle_spell then
                character.current_scan_action.reticle_spell:delete()
            end
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
            if #targets > 0 then
                local action = action_scan(character)
                action.action_end_func = function ()
                    print('scanning ended')
                    character.current_scan_action = nil
                end
                character.current_scan_action = action
                self.ai_state = "scanning"
                character:card_action_event(action, ActionOrder.Voluntary)
            end
        end
    end
    self.battle_start_func = function (self)
        debug_print("battle_start_func called")
    end
    self.battle_end_func = function (self)
        debug_print("battle_end_func called")
    end
    self.on_spawn_func = function (self, spawn_tile) 
        debug_print("on_spawn_func called")
   end
    self.delete_func = function (self)
        debug_print("delete_func called")
        scanning_interrupt()
    end
end

return package_init